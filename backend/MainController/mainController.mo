import UserReg "canister:user-registry";
import ProjectMgr "canister:project-manager";  
import PaymentEsc "canister:payment-escrow";
import RepSystem "canister:reputation-system";

actor MainController {
    
    // Workflow completo de projeto
    public shared(msg) func complete_project_workflow(
        project_id: Nat, 
        proposal_id: Nat
    ) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        // 1. Aceitar proposta no Project Manager
        switch (await ProjectMgr.accept_proposal(proposal_id)) {
            case (#err(e)) { return #err("Failed to accept proposal: " # e) };
            case (#ok(_)) {};
        };
        
        // 2. Obter detalhes do projeto
        switch (await ProjectMgr.get_project(project_id)) {
            case null { return #err("Project not found") };
            case (?project) {
                switch (project.selected_freelancer) {
                    case null { return #err("No freelancer selected") };
                    case (?freelancer_id) {
                        // 3. Criar contrato de escrow
                        let milestones = [
                            ("Initial milestone", project.budget / 2),
                            ("Final delivery", project.budget / 2)
                        ];
                        
                        switch (await PaymentEsc.create_escrow(project_id, freelancer_id, milestones)) {
                            case (#err(e)) { return #err("Failed to create escrow: " # e) };
                            case (#ok(escrow_id)) {
                                // 4. Atualizar contadores de projetos dos usuários
                                ignore UserReg.increment_projects(caller);
                                ignore UserReg.increment_projects(freelancer_id);
                                
                                #ok("Project workflow completed successfully. Escrow ID: " # Nat.toText(escrow_id))
                            };
                        }
                    };
                }
            };
        }
    };
    
    // Finalizar projeto com review
    public shared(msg) func finalize_project_with_review(
        project_id: Nat,
        freelancer_id: Principal,
        rating: Nat,
        comment: Text
    ) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        // 1. Completar projeto
        switch (await ProjectMgr.complete_project(project_id)) {
            case (#err(e)) { return #err("Failed to complete project: " # e) };
            case (#ok(_)) {};
        };
        
        // 2. Submeter review
        switch (await RepSystem.submit_review(project_id, freelancer_id, rating, comment, #ClientToFreelancer)) {
            case (#err(e)) { return #err("Failed to submit review: " # e) };
            case (#ok(review_id)) {
                // 3. Atualizar reputação baseada no rating
                let reputation_change = if (rating >= 4) 10 else if (rating >= 3) 0 else -5;
                ignore UserReg.update_reputation(freelancer_id, reputation_change);
                
                #ok("Project finalized and reviewed successfully. Review ID: " # Nat.toText(review_id))
            };
        }
    };
    
    // Obter dashboard completo de um usuário
    public func get_user_dashboard(user_id: Principal) : async {
        profile: ?UserReg.UserProfile;
        reputation: ?RepSystem.ReputationStats;
        balance: Nat;
    } {
        let profile = await UserReg.get_user_profile(user_id);
        let reputation = await RepSystem.get_reputation_stats(user_id);
        
        // Para obter o saldo, precisaríamos de uma função específica no PaymentEscrow
        // que aceite queries de outros contratos, ou usar shared query
        let balance = 0; // Simplificado por questões de inter-canister queries
        
        {
            profile = profile;
            reputation = reputation;
            balance = balance;
        }
    };
    
    // Buscar freelancers por skill
    public func search_freelancers_by_skill(skill: Text) : async [UserReg.UserProfile] {
        let all_freelancers = await UserReg.get_all_freelancers();
        Array.filter<UserReg.UserProfile>(all_freelancers, func(freelancer) = 
            Array.find<Text>(freelancer.skills, func(s) = Text.equal(s, skill)) != null
        )
    };
    
    // Obter marketplace overview
    public func get_marketplace_overview() : async {
        open_projects: [ProjectMgr.Project];
        top_freelancers: [RepSystem.ReputationStats];
        total_users: Nat;
    } {
        let open_projects = await ProjectMgr.get_open_projects();
        let top_freelancers = await RepSystem.get_top_rated_users(10);
        let all_freelancers = await UserReg.get_all_freelancers();
        
        {
            open_projects = open_projects;
            top_freelancers = top_freelancers;
            total_users = all_freelancers.size();
        }
    };
}