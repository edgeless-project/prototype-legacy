# Examples

- `incr`: expects that a JSON message is posted with a number in `input` and returns a JSON file with the number incremented in the `output` field
- `double`: same as `incr` but doubles the input

## How to build

See [OpenFaaS template for Rust](https://github.com/openfaas-incubator/rust-http-template) instructions, e.g.:

```
faas template pull https://github.com/openfaas-incubator/rust-http-template
```

Add `RUN apk add --no-cache musl-dev` before `cargo build` in `template/rust/Dockerfile`, then you can build the function:

```
DOCKER_BUILDKIT=1 faas-cli build -f incr.yml
```

To run locally with Docker:

```
docker run -p 8080:8080 ccicconetti/incr 
```