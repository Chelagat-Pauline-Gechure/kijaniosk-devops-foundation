# k8s/ Directory

All manifests are applied with: kubectl apply -f k8s/

## Secret Recovery

The kk-payments-secrets Secret is NOT committed to git (security requirement).
After a cluster reset, recreate it manually before applying any manifests:

    kubectl create secret generic kk-payments-secrets \
      --from-literal=DB_PASSWORD=<obtain from team lead> \
      --from-literal=STRIPE_API_KEY=<obtain from team lead> \
      --from-literal=JWT_SECRET=<obtain from team lead> \
      -n kijani-project

Secret name: kk-payments-secrets
Expected keys: DB_PASSWORD, STRIPE_API_KEY, JWT_SECRET
Where to get values: Contact the team lead before applying payment manifests.
