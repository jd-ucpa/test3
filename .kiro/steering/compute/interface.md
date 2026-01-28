je veux créer un exécutable bash qui calcule une addition et retourne une résultat

Exemple de l'interface CLI voulue :

```bash
./compute.sh add 2 3
{
  "status": "success",
  "data": {
    "params": {
      "action": "add",
      "arguments": [2, 3]
    }
  },
  "result": 5
}
```
