actor ReputationSystem {
    
    public type ReviewType = {
        #ClientToFreelancer;
        #FreelancerToClient;
    };
    
    public type Review = {
        review_id: Nat;
        project_id: Nat;
        reviewer_id: Principal;
        reviewed_id: Principal;
        rating: Nat; // 1-5 stars
        comment: Text;
        review_type: ReviewType;
        created_at: Int;
    };
    
    public type ReputationStats = {
        user_id: Principal;
        total_reviews: Nat;
        average_rating: Float;
        total_completed_projects: Nat;
        badges: [Text];
        last_updated: Int;
    };
    
    private stable var reviews_entries : [(Nat, Review)] = [];
    private stable var reputation_entries : [(Principal, ReputationStats)] = [];
    private stable var review_counter = 0;
    
    private var reviews = HashMap.fromIter<Nat, Review>(reviews_entries.vals(), 10, Nat.equal, Nat32.fromNat);
    private var reputation_stats = HashMap.fromIter<Principal, ReputationStats>(reputation_entries.vals(), 10, Principal.equal, Principal.hash);
    
    system func preupgrade() {
        reviews_entries := reviews.entries() |> Array.fromIter(_);
        reputation_entries := reputation_stats.entries() |> Array.fromIter(_);
    };
    
    system func postupgrade() {
        reviews_entries := [];
        reputation_entries := [];
    };
    
    // Submeter review
    public shared(msg) func submit_review(
        project_id: Nat, 
        reviewed_id: Principal, 
        rating: Nat, 
        comment: Text,
        review_type: ReviewType
    ) : async Result.Result<Nat, Text> {
        let caller = msg.caller;
        
        if (rating < 1 or rating > 5) {
            return #err("Rating must be between 1 and 5")
        };
        
        if (Principal.equal(caller, reviewed_id)) {
            return #err("Cannot review yourself")
        };
        
        review_counter += 1;
        
        let review : Review = {
            review_id = review_counter;
            project_id = project_id;
            reviewer_id = caller;
            reviewed_id = reviewed_id;
            rating = rating;
            comment = comment;
            review_type = review_type;
            created_at = Time.now();
        };
        
        reviews.put(review_counter, review);
        update_reputation_stats(reviewed_id);
        
        #ok(review_counter)
    };
    
    // Atualizar estatísticas de reputação
    private func update_reputation_stats(user_id: Principal) : () {
        let user_reviews = reviews.vals() 
        |> Array.fromIter(_)
        |> Array.filter<Review>(_, func(r) = Principal.equal(r.reviewed_id, user_id));
        
        if (user_reviews.size() == 0) {
            return ()
        };
        
        let total_reviews = user_reviews.size();
        let total_rating = Array.foldLeft<Review, Nat>(user_reviews, 0, func(acc, r) = acc + r.rating);
        let average_rating : Float = Float.fromInt(total_rating) / Float.fromInt(total_reviews);
        
        // Determinar badges
        var badges : [Text] = [];
        
        if (average_rating >= 4.8) {
            badges := Array.append<Text>(badges, ["Excellent Service"]);
        };
        
        if (total_reviews >= 10) {
            badges := Array.append<Text>(badges, ["Experienced Professional"]);
        };
        
        if (total_reviews >= 50) {
            badges := Array.append<Text>(badges, ["Top Rated"]);
        };
        
        let stats : ReputationStats = {
            user_id = user_id;
            total_reviews = total_reviews;
            average_rating = average_rating;
            total_completed_projects = total_reviews; // Simplificado
            badges = badges;
            last_updated = Time.now();
        };
        
        reputation_stats.put(user_id, stats);
    };
    
    // Obter reviews de um usuário
    public query func get_user_reviews(user_id: Principal) : async [Review] {
        reviews.vals()
        |> Array.fromIter(_)
        |> Array.filter<Review>(_, func(r) = Principal.equal(r.reviewed_id, user_id))
    };
    
    // Obter estatísticas de reputação
    public query func get_reputation_stats(user_id: Principal) : async ?ReputationStats {
        reputation_stats.get(user_id)
    };
    
    // Obter top usuários
    public query func get_top_rated_users(limit: Nat) : async [ReputationStats] {
        let all_stats = reputation_stats.vals() |> Array.fromIter(_);
        let sorted = Array.sort<ReputationStats>(all_stats, func(a, b) = 
            if (a.average_rating > b.average_rating) #less
            else if (a.average_rating < b.average_rating) #greater  
            else #equal
        );
        Array.take<ReputationStats>(sorted, limit)
    };
    
    // Obter review específico
    public query func get_review(review_id: Nat) : async ?Review {
        reviews.get(review_id)
    };
}