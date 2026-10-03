# Recommendation System (Netflix / YouTube / Amazon "recommended for you"): High-Level Design

**Asked at:** Netflix, YouTube (Google), Amazon, Meta, TikTok, Spotify, Pinterest. **Core topics:** multi-stage funnel (candidate generation -> ranking -> re-ranking), collaborative filtering and embeddings, approximate nearest neighbor search, feature stores, offline training vs online serving, cold start, feedback loops and evaluation.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Surface? | A home page row "Recommended for you" (also "similar items" on item pages). |
| Catalog? | 10 M items (videos/products). |
| Users? | 200 M DAU; each home page load requests ~50 recommendations. |
| Latency? | < 200 ms for the whole funnel. |
| Freshness? | New user actions influence results within minutes; models retrained daily. |
| Goal metric? | Engagement (watch time / purchases), measured by A/B tests. |

## 2. Requirements

**Functional:** personalized ranked list per user; similar-item lists; handle new users and new items; exclude already consumed or blocked items; explanations ("because you watched X").

**Non-functional:** low latency at high QPS, scalable training on billions of interactions, fresh signals, diversity and fairness constraints, experimentation support.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Requests | 200 M x ~5 home loads/day | **~12K/s** avg, ~40K/s peak |
| Interactions logged | 200 M x ~100 events/day | **~20 B events/day** (~230K/s) |
| Embeddings | 10 M items x 128 floats x 4 B | **~5 GB**: fits in memory on each ANN server |
| Ranking cost | 500 candidates x model inference | batched on CPUs/GPUs; must fit the latency budget |

## 4. The funnel

```text
 10 M items --candidate generation (fast, recall-oriented)--> ~1,000 candidates
            sources: item-item collaborative filtering from recent history, user embedding ANN search,
                     trending/popular, followed creators, fresh items
          --ranking (expensive model, precision-oriented: predicted watch time / click / purchase)--> scored
          --re-ranking (business rules: diversity, freshness, dedupe, already-seen filter, policy)--> top 50
```

Each stage trades cost per item for accuracy; only a small set reaches the expensive model.

## 5. Architecture

```text
 events (clicks, watches, purchases) --> Kafka --> stream features (recent activity, counters) --> feature store (online)
                                             \--> data lake --> offline training (daily): embeddings, CF tables,
                                                               ranking model --> model registry
 request --> Recommendation service:
                1. fetch user features + recent history (feature store)
                2. candidate generators in parallel (ANN index over item embeddings, CF tables, popular lists)
                3. ranking service (batched model inference with user + item + context features)
                4. re-ranker (diversity, filters) --> response; log impressions for training and evaluation
```

## 6. Deep dives

- **Collaborative filtering:** "users who liked A also liked B". Item-item similarity from co-occurrence (cosine) is simple, explainable and stable; matrix factorization / two-tower neural models learn embeddings for users and items so a dot product predicts affinity.
- **Approximate nearest neighbor (ANN):** find items whose embeddings are closest to the user's embedding among 10 M in milliseconds (HNSW graphs, IVF + product quantization).
- **Cold start:** new users get popular/trending items and onboarding choices; new items get content-based features (text, category) and exploration traffic.
- **Re-ranking:** limit items per category/creator, inject fresh items, remove already-watched items, respect content policies.
- **Feedback loops:** the system only learns from what it shows; reserve some exploration traffic; log impressions (not just clicks) to train on negatives too.
- **Evaluation:** offline metrics (recall@k, NDCG on held-out interactions) to filter ideas; online A/B tests decide.

## 7. Failure modes

| Failure | Behavior |
|---|---|
| Ranking service slow | Timeout; serve candidates ordered by a cheap score. |
| Feature store unavailable | Default features; degrade personalization, never return errors. |
| Bad model deployed | Canary by traffic percentage; automatic rollback on metric drops. |
| Training pipeline late | Serve yesterday's model and tables. |

## 8. What interviewers look for

- The multi-stage funnel and why.
- At least one concrete candidate generation method (item-item CF, embeddings + ANN).
- Offline training vs online serving with a feature store.
- Cold start, diversity, feedback loops, evaluation.

## 9. Common mistakes

- Scoring all 10 M items with a heavy model per request.
- Ignoring cold start.
- Optimizing only offline metrics.
- Training only on clicks without impressions (no negatives, popularity bias).

## 10. Follow-ups

1. **Real-time session recommendations:** sequence models over the last few actions.
2. **Multi-objective ranking:** blend engagement, satisfaction surveys, and business goals.
3. **Fairness to creators:** exposure constraints in re-ranking.

See [LLD.md](LLD.md) for item-item collaborative filtering, candidate scoring with explanations, popularity fallback, diversity re-ranking and an offline hit-rate evaluation.
