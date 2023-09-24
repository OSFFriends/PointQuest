```mermaid
---
User Registration
---
sequenceDiagram

participant User
participant PointQuest

User ->> PointQuest: browse to app
PointQuest ->> User: no token detected, prompt for registration
User ->> PointQeust: create user
PointQuest ->> User: redirect to dashboard
User ->> PointQuest: select User path on dashboard
PointQuest ->> User: present character list for User
```
