```mermaid
---
Project Manager Registration
---

sequenceDiagram

participant User
participant PointQuest
participant Linear

User->>PointQuest: browse to app
PointQuest->>User: no token detected, prompt for registration
User->>PointQuest: create user
PointQuest->>User: redirect to dashboard
User->>PointQuest: select PM path on dashboard
PointQuest->>User: Oauth authorization with linear
PointQuest->>Linear: request list of teams
Linear->>PointQuest: list of teams
PointQuest->>User: display list of teams
User->>PointQuest: pick team
PointQuest->>Linear: request issues for team
Linear->>PointQuest: list of issues
PointQuest->>User: display issues
```
