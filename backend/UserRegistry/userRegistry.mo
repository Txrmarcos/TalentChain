import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

actor UserRegistry {
    
    public type UserType = {
        #Freelancer;
        #Client;
        #Both;
    };
    
    public type UserProfile = {
        user_id: Principal;
        name: Text;
        email: Text;
        user_type: UserType;
        skills: [Text];
        reputation_score: Nat;
        total_projects: Nat;
        created_at: Int;
    };
    
    private stable var users_entries : [(Principal, UserProfile)] = [];
    private var users = HashMap.fromIter<Principal, UserProfile>(users_entries.vals(), 10, Principal.equal, Principal.hash);
    
    // Persistência dos dados
    system func preupgrade() {
        users_entries := users.entries() |> Array.fromIter(_);
    };
    
    system func postupgrade() {
        users_entries := [];
    };
    
    // Registrar novo usuário
    public shared(msg) func register_user(name: Text, email: Text, user_type: UserType, skills: [Text]) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (users.get(caller)) {
            case (?_) { #err("User already registered") };
            case null {
                let profile : UserProfile = {
                    user_id = caller;
                    name = name;
                    email = email;
                    user_type = user_type;
                    skills = skills;
                    reputation_score = 100;
                    total_projects = 0;
                    created_at = Time.now();
                };
                
                users.put(caller, profile);
                #ok("User registered successfully")
            };
        }
    };
    
    // Obter perfil do usuário
    public query func get_user_profile(user_id: Principal) : async ?UserProfile {
        users.get(user_id)
    };
    
    // Atualizar reputação
    public func update_reputation(user_id: Principal, score_change: Int) : async Result.Result<Text, Text> {
        switch (users.get(user_id)) {
            case null { #err("User not found") };
            case (?user) {
                let new_score = if (score_change < 0 and Int.abs(score_change) > user.reputation_score) {
                    0
                } else {
                    Int.abs(user.reputation_score + score_change)
                };
                
                let updated_user = {
                    user with reputation_score = new_score
                };
                
                users.put(user_id, updated_user);
                #ok("Reputation updated")
            };
        }
    };
    
    // Incrementar projetos concluídos
    public func increment_projects(user_id: Principal) : async Result.Result<Text, Text> {
        switch (users.get(user_id)) {
            case null { #err("User not found") };
            case (?user) {
                let updated_user = {
                    user with total_projects = user.total_projects + 1
                };
                users.put(user_id, updated_user);
                #ok("Projects incremented")
            };
        }
    };
    
    // Listar todos os freelancers
    public query func get_all_freelancers() : async [UserProfile] {
        users.vals() 
        |> Array.fromIter(_)
        |> Array.filter<UserProfile>(_, func(user) = 
            user.user_type == #Freelancer or user.user_type == #Both
        )
    };
}
