# FIX FRONTEND - Monitored App bulk collect chunking

## Contexte et symptomes

Le backend limite maintenant les charges de collecte afin d'eviter la saturation de
`POST /api/v1/data/collect/bulk/` sous ASGI:

- maximum 200 items par requete bulk;
- maximum 100 items pour un meme `data_type`;
- depassement: `413 Request Entity Too Large` avec `code` stable.

Sans fractionnement cote monitored_app, le premier bootstrap apres jumelage peut
etre rejete, notamment avec les lots SMS, appels, apps installees et usage apps.

## Racine technique

Le backend traite les lots en ecritures groupees et utilise une cle de
deduplication par ligne. Pour garder une latence bornee, il refuse les payloads
trop volumineux au lieu de monopoliser le thread sync ASGI.

## Portee d'impact

Application concernee: monitored_app.

Flux concernes:

- collecte initiale apres jumelage;
- synchronisation de rattrapage;
- re-envoi d'items non marques comme synchronises;
- gestion d'erreur de `POST /api/v1/data/collect/bulk/`.

Monitor_app n'a pas de changement de contrat a prevoir pour l'affichage des
devices. L'effet attendu est que `GET /api/v1/devices/devices/` reste disponible
pendant les envois monitored_app.

## Contrat backend attendu

Endpoint:

```http
POST /api/v1/data/collect/bulk/
Authorization: Bearer <access_token>
Content-Type: application/json
```

Payload accepte:

```json
{
  "device_id": "<device_uuid>",
  "data_batches": [
    {
      "data_type": "messages",
      "items": [{ "body": "...", "sent_at": "2026-05-12T08:00:00Z" }]
    }
  ],
  "metadata": {
    "sync_timestamp": "2026-05-16T05:00:00Z"
  }
}
```

Rejet total trop grand:

```json
{
  "code": "payload_too_large",
  "detail": "Bulk depasse 200 items (recu 201). Fractionner cote client."
}
```

Rejet d'un type trop grand:

```json
{
  "code": "batch_too_large",
  "detail": "Lot messages depasse 100 items."
}
```

## Changements Flutter requis

Dans le service/repository monitored_app qui construit le payload bulk:

1. Regrouper les items par `data_type`.
2. Decouper chaque groupe en chunks de 100 items maximum.
3. Assembler des requetes bulk dont la somme des `items` ne depasse jamais 200.
4. Envoyer les requetes sequentiellement ou avec une concurrence tres limitee.
5. En cas de `413`, rediviser le payload local en chunks plus petits et reessayer
   avec backoff borne.
6. Marquer les items comme synchronises seulement apres une reponse `200` ou
   `207` ou le lot concerne est effectivement traite.

Pseudo-code:

```dart
const maxItemsPerBulk = 200;
const maxItemsPerType = 100;

final chunksByType = <BulkBatch>[];
for (final entry in itemsByType.entries) {
  for (final chunk in chunked(entry.value, maxItemsPerType)) {
    chunksByType.add(BulkBatch(dataType: entry.key, items: chunk));
  }
}

for (final requestBatches in packBatches(chunksByType, maxItemsPerBulk)) {
  await api.postBulkCollect(deviceId: deviceId, dataBatches: requestBatches);
}
```

## Verification

- Jumelage frais avec au moins 149 SMS, 140 appels et 160 apps.
- Aucun `POST /data/collect/bulk/` ne depasse 200 items au total.
- Aucun batch interne ne depasse 100 items.
- Si un `413` est simule, monitored_app re-chunk et reessaie sans boucle infinie.
- Apres bootstrap, les items sont marques synchronises une seule fois.
- Pendant l'envoi, monitor_app affiche la liste des appareils en moins de 5 s.

## Ordre de deploiement

1. Deployer le backend avec les migrations `dedup_key`.
2. Deployer monitored_app avec le chunking.
3. Garder le retry/backoff existant cote monitor_app pour les erreurs reseau
   transitoires.
