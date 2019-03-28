# NewsIngester

Gateway for crawling news from providers and posting them with GraphQL

## Reqiured environment variables

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

API_USERNAME

API_PASSWORD

GRAPHQL_URL

GRAPHQL_TOKEN

GOOGLE_APPLICATION_CREDENTIALS

ASSET_MANIPULATOR_ENDPOINT

## Getting Started

### Prerequisites

```
Elixir 1.7
Amazon DynamoDB
```

### Running the application

Just execute

```
mix run --no-halt
```

### Running the docker container

* Build image with

```
docker build --tag=news_ingester .
```

* Set environment variables in `.docker_env` file

* Run image with
```
docker run --env-file=.docker_env news_ingester
``` 


with required environment variables

### Running the tests

```
mix test
```
