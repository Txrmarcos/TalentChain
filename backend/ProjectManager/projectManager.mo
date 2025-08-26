actor ProjectManager {
    
    public type ProjectStatus = {
        #Open;
        #InProgress;
        #Completed;
        #Cancelled;
    };
    
    public type ProposalStatus = {
        #Pending;
        #Accepted;
        #Rejected;
    };
    
    public type Project = {
        project_id: Nat;
        client_id: Principal;
        title: Text;
        description: Text;
        budget: Nat;
        required_skills: [Text];
        status: ProjectStatus;
        created_at: Int;
        deadline: Int;
        selected_freelancer: ?Principal;
    };
    
    public type Proposal = {
        proposal_id: Nat;
        project_id: Nat;
        freelancer_id: Principal;
        proposed_budget: Nat;
        timeline_days: Nat;
        message: Text;
        status: ProposalStatus;
        created_at: Int;
    };
    
    private stable var projects_entries : [(Nat, Project)] = [];
    private stable var proposals_entries : [(Nat, Proposal)] = [];
    private stable var project_counter = 0;
    private stable var proposal_counter = 0;
    
    private var projects = HashMap.fromIter<Nat, Project>(projects_entries.vals(), 10, Nat.equal, Nat32.fromNat);
    private var proposals = HashMap.fromIter<Nat, Proposal>(proposals_entries.vals(), 10, Nat.equal, Nat32.fromNat);
    
    system func preupgrade() {
        projects_entries := projects.entries() |> Array.fromIter(_);
        proposals_entries := proposals.entries() |> Array.fromIter(_);
    };
    
    system func postupgrade() {
        projects_entries := [];
        proposals_entries := [];
    };
    
    // Criar novo projeto
    public shared(msg) func create_project(
        title: Text, 
        description: Text, 
        budget: Nat, 
        required_skills: [Text], 
        deadline_days: Nat
    ) : async Result.Result<Nat, Text> {
        let caller = msg.caller;
        project_counter += 1;
        
        let project : Project = {
            project_id = project_counter;
            client_id = caller;
            title = title;
            description = description;
            budget = budget;
            required_skills = required_skills;
            status = #Open;
            created_at = Time.now();
            deadline = Time.now() + (deadline_days * 24 * 60 * 60 * 1_000_000_000);
            selected_freelancer = null;
        };
        
        projects.put(project_counter, project);
        #ok(project_counter)
    };
    
    // Submeter proposta
    public shared(msg) func submit_proposal(
        project_id: Nat, 
        proposed_budget: Nat, 
        timeline_days: Nat, 
        message: Text
    ) : async Result.Result<Nat, Text> {
        let caller = msg.caller;
        
        switch (projects.get(project_id)) {
            case null { #err("Project not found") };
            case (?project) {
                if (project.status != #Open) {
                    return #err("Project is not open for proposals")
                };
                
                proposal_counter += 1;
                
                let proposal : Proposal = {
                    proposal_id = proposal_counter;
                    project_id = project_id;
                    freelancer_id = caller;
                    proposed_budget = proposed_budget;
                    timeline_days = timeline_days;
                    message = message;
                    status = #Pending;
                    created_at = Time.now();
                };
                
                proposals.put(proposal_counter, proposal);
                #ok(proposal_counter)
            };
        }
    };
    
    // Aceitar proposta
    public shared(msg) func accept_proposal(proposal_id: Nat) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (proposals.get(proposal_id)) {
            case null { #err("Proposal not found") };
            case (?proposal) {
                switch (projects.get(proposal.project_id)) {
                    case null { #err("Project not found") };
                    case (?project) {
                        if (project.client_id != caller) {
                            return #err("Only project client can accept proposals")
                        };
                        
                        // Atualizar proposta
                        let updated_proposal = { proposal with status = #Accepted };
                        proposals.put(proposal_id, updated_proposal);
                        
                        // Atualizar projeto
                        let updated_project = {
                            project with 
                            status = #InProgress;
                            selected_freelancer = ?proposal.freelancer_id;
                        };
                        projects.put(proposal.project_id, updated_project);
                        
                        // Rejeitar outras propostas do mesmo projeto
                        for ((id, prop) in proposals.entries()) {
                            if (prop.project_id == proposal.project_id and id != proposal_id) {
                                let rejected_prop = { prop with status = #Rejected };
                                proposals.put(id, rejected_prop);
                            }
                        };
                        
                        #ok("Proposal accepted successfully")
                    };
                }
            };
        }
    };
    
    // Listar projetos abertos
    public query func get_open_projects() : async [Project] {
        projects.vals() 
        |> Array.fromIter(_)
        |> Array.filter<Project>(_, func(p) = p.status == #Open)
    };
    
    // Obter propostas de um projeto
    public query func get_project_proposals(project_id: Nat) : async [Proposal] {
        proposals.vals()
        |> Array.fromIter(_)
        |> Array.filter<Proposal>(_, func(p) = p.project_id == project_id)
    };
    
    // Obter projeto específico
    public query func get_project(project_id: Nat) : async ?Project {
        projects.get(project_id)
    };
    
    // Completar projeto
    public shared(msg) func complete_project(project_id: Nat) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (projects.get(project_id)) {
            case null { #err("Project not found") };
            case (?project) {
                if (project.client_id != caller) {
                    return #err("Only client can complete project")
                };
                
                let updated_project = { project with status = #Completed };
                projects.put(project_id, updated_project);
                #ok("Project completed successfully")
            };
        }
    };
}
