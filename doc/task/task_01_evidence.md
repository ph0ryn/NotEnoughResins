# Task 01 Evidence - HoYoLAB Contract

## Execution Summary

- Date: 2026-03-11
- Inputs: `.env` `HOYOLAB_COOKIE`
- Scope: read-only live requests to the two approved HoYoLAB URLs
- Secret handling: cookies, account IDs, role IDs, and nicknames are redacted
  from this artifact

## Confirmed Endpoints

### Game Record Card

- Method: `GET`
- URL:
  `https://sg-public-api.hoyolab.com/event/game_record/card/wapi/getGameRecordCard`
- Query: `uid={account_id_v2}`

### Daily Note

- Method: `GET`
- URL:
  `https://sg-public-api.hoyolab.com/event/game_record/app/genshin/api/dailyNote`
- Query: `server={region}`, `role_id={game_role_id}`

## Confirmed Shared Header Set

- Tested minimal shared header set: `Cookie`
- Also tolerated in live calls: `Accept`, `x-rpc-client_type`,
  `x-rpc-app_version`, `x-rpc-language`, `User-Agent`
- `DS` was not required in the tested calls

## Confirmed Mapping

1. Extract `account_id_v2` from the saved cookie.
2. Call the game record card endpoint with `uid={account_id_v2}`.
3. Select the entry where `game_id == 2`.
4. Map `region -> server`.
5. Map `game_role_id -> role_id`.

Observed sanitized Genshin entry:

```json
{
  "game_id": 2,
  "game_name": "原神",
  "region": "os_asia",
  "region_name": "Asia Server",
  "game_role_id": "<redacted-role-id>",
  "nickname": "<redacted-nickname>",
  "level": 60,
  "has_role": true
}
```

## Confirmed Response Envelope

Both endpoints returned the same top-level shape in the tested responses:

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {}
}
```

Sanitized game record card success sample:

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "game_id": 2,
        "game_name": "原神",
        "region": "os_asia",
        "region_name": "Asia Server",
        "game_role_id": "<redacted-role-id>",
        "nickname": "<redacted-nickname>",
        "level": 60,
        "has_role": true
      }
    ]
  }
}
```

Sanitized Daily Note success sample:

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "current_resin": 200,
    "max_resin": 200,
    "resin_recovery_time": "0",
    "current_home_coin": 2400,
    "max_home_coin": 2400,
    "home_coin_recovery_time": "0",
    "finished_task_num": 4,
    "total_task_num": 4,
    "is_extra_task_reward_received": true,
    "remain_resin_discount_num": 3,
    "resin_discount_num_limit": 3,
    "current_expedition_num": 0,
    "max_expedition_num": 5,
    "expeditions": [],
    "daily_task": {},
    "transformer": {},
    "calendar_url": "<redacted-url>",
    "archon_quest_progress": {}
  }
}
```

## Confirmed Failure Classification

All tested failures still returned HTTP `200`. The app must classify results
from `retcode` and `message`.

### Auth Failure

- Observed on both endpoints with an invalid cookie
- `retcode = 10001`
- `message = "Please login"`

Sanitized auth failure sample:

```json
{
  "retcode": 10001,
  "message": "Please login",
  "data": null
}
```

### Generic Request Failure

- Observed on game record card with invalid `uid`
- Observed on Daily Note with invalid `role_id`
- `retcode = -1`
- Messages were parameter-specific

Sanitized request failure samples:

```json
{
  "retcode": -1,
  "message": "Invalid uid",
  "data": null
}
```

```json
{
  "retcode": -1,
  "message": "param role_id error: value must be greater than 0",
  "data": null
}
```

## Implementation Implications

- `AccountResolver` can depend on `region` and `game_role_id` from the selected
  `game_id == 2` card entry.
- `DailyNoteService` should classify auth failures from the `10001` /
  `"Please login"` signature.
- `DailyNoteService` should treat other non-zero `retcode` values as
  request-level failures unless later evidence defines a narrower rule.
- The networking layer must parse the HoYoLAB JSON payload even when the HTTP
  status is `200` but the request semantically failed.
