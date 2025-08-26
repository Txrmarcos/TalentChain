actor PaymentEscrow {
    
    public type EscrowStatus = {
        #Created;
        #Funded;
        #InProgress;
        #Completed;
        #Disputed;
        #Cancelled;
    };
    
    public type MilestoneStatus = {
        #Pending;
        #Completed;
        #Approved;
        #Disputed;
    };
    
    public type Milestone = {
        milestone_id: Nat;
        description: Text;
        amount: Nat;
        status: MilestoneStatus;
        completed_at: ?Int;
    };
    
    public type EscrowContract = {
        contract_id: Nat;
        project_id: Nat;
        client_id: Principal;
        freelancer_id: Principal;
        amount: Nat;
        status: EscrowStatus;
        created_at: Int;
        milestones: [Milestone];
    };
    
    private stable var escrow_entries : [(Nat, EscrowContract)] = [];
    private stable var balance_entries : [(Principal, Nat)] = [];
    private stable var escrow_counter = 0;
    
    private var escrow_contracts = HashMap.fromIter<Nat, EscrowContract>(escrow_entries.vals(), 10, Nat.equal, Nat32.fromNat);
    private var balances = HashMap.fromIter<Principal, Nat>(balance_entries.vals(), 10, Principal.equal, Principal.hash);
    
    system func preupgrade() {
        escrow_entries := escrow_contracts.entries() |> Array.fromIter(_);
        balance_entries := balances.entries() |> Array.fromIter(_);
    };
    
    system func postupgrade() {
        escrow_entries := [];
        balance_entries := [];
    };
    
    // Criar contrato de escrow
    public shared(msg) func create_escrow(
        project_id: Nat, 
        freelancer_id: Principal, 
        milestone_data: [(Text, Nat)]
    ) : async Result.Result<Nat, Text> {
        let caller = msg.caller;
        escrow_counter += 1;
        
        let total_amount = Array.foldLeft<(Text, Nat), Nat>(milestone_data, 0, func(acc, (_, amount)) = acc + amount);
        
        let milestones = Array.mapEntries<(Text, Nat), Milestone>(milestone_data, func((desc, amount), i) = {
            milestone_id = i;
            description = desc;
            amount = amount;
            status = #Pending;
            completed_at = null;
        });
        
        let contract : EscrowContract = {
            contract_id = escrow_counter;
            project_id = project_id;
            client_id = caller;
            freelancer_id = freelancer_id;
            amount = total_amount;
            status = #Created;
            created_at = Time.now();
            milestones = milestones;
        };
        
        escrow_contracts.put(escrow_counter, contract);
        #ok(escrow_counter)
    };
    
    // Financiar escrow
    public shared(msg) func fund_escrow(contract_id: Nat, amount: Nat) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        let user_balance = switch (balances.get(caller)) {
            case (?balance) balance;
            case null 0;
        };
        
        if (user_balance < amount) {
            return #err("Insufficient balance")
        };
        
        switch (escrow_contracts.get(contract_id)) {
            case null { #err("Contract not found") };
            case (?contract) {
                if (contract.client_id != caller) {
                    return #err("Only client can fund escrow")
                };
                
                if (contract.amount != amount) {
                    return #err("Amount mismatch")
                };
                
                // Atualizar contrato
                let updated_contract = { contract with status = #Funded };
                escrow_contracts.put(contract_id, updated_contract);
                
                // Deduzir saldo do cliente
                balances.put(caller, user_balance - amount);
                
                #ok("Escrow funded successfully")
            };
        }
    };
    
    // Completar milestone
    public shared(msg) func complete_milestone(contract_id: Nat, milestone_id: Nat) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (escrow_contracts.get(contract_id)) {
            case null { #err("Contract not found") };
            case (?contract) {
                if (contract.freelancer_id != caller) {
                    return #err("Only freelancer can complete milestones")
                };
                
                if (milestone_id >= contract.milestones.size()) {
                    return #err("Milestone not found")
                };
                
                let updated_milestones = Array.mapEntries<Milestone, Milestone>(contract.milestones, func(milestone, i) = {
                    if (i == milestone_id) {
                        {
                            milestone with 
                            status = #Completed;
                            completed_at = ?Time.now();
                        }
                    } else {
                        milestone
                    }
                });
                
                let updated_contract = { contract with milestones = updated_milestones };
                escrow_contracts.put(contract_id, updated_contract);
                
                #ok("Milestone completed")
            };
        }
    };
    
    // Aprovar milestone
    public shared(msg) func approve_milestone(contract_id: Nat, milestone_id: Nat) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (escrow_contracts.get(contract_id)) {
            case null { #err("Contract not found") };
            case (?contract) {
                if (contract.client_id != caller) {
                    return #err("Only client can approve milestones")
                };
                
                if (milestone_id >= contract.milestones.size()) {
                    return #err("Milestone not found")
                };
                
                let milestone = contract.milestones[milestone_id];
                if (milestone.status != #Completed) {
                    return #err("Milestone not completed yet")
                };
                
                // Atualizar milestone
                let updated_milestones = Array.mapEntries<Milestone, Milestone>(contract.milestones, func(m, i) = {
                    if (i == milestone_id) {
                        { m with status = #Approved }
                    } else {
                        m
                    }
                });
                
                let updated_contract = { contract with milestones = updated_milestones };
                escrow_contracts.put(contract_id, updated_contract);
                
                // Transferir pagamento para freelancer
                let freelancer_balance = switch (balances.get(contract.freelancer_id)) {
                    case (?balance) balance;
                    case null 0;
                };
                balances.put(contract.freelancer_id, freelancer_balance + milestone.amount);
                
                #ok("Milestone approved and payment released")
            };
        }
    };
    
    // Adicionar saldo (simulação de depósito)
    public shared(msg) func add_balance(amount: Nat) : async Text {
        let caller = msg.caller;
        let current_balance = switch (balances.get(caller)) {
            case (?balance) balance;
            case null 0;
        };
        balances.put(caller, current_balance + amount);
        "Added " # Nat.toText(amount) # " to balance"
    };
    
    // Obter saldo
    public shared query(msg) func get_balance() : async Nat {
        let caller = msg.caller;
        switch (balances.get(caller)) {
            case (?balance) balance;
            case null 0;
        }
    };
    
    // Obter contrato
    public query func get_escrow_contract(contract_id: Nat) : async ?EscrowContract {
        escrow_contracts.get(contract_id)
    };
}