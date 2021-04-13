# Development

To run the operator locally without creating any new image:
* You can run the operator locally watching all namespaces (default behaviour):
```bash
make run
```
* Or watching a specific namespace using envvar `WATCH_NAMESPACE`:
```bash
make run WATCH_NAMESPACE=example
```