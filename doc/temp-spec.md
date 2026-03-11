# spec

`Genshin`のゲーム内スタミナ`resin`のマネージャーmacアプリ
ウィンドウは持たず、メニューバーに表示する

## 取得

GETリクエスト

url: `https://sg-public-api.hoyolab.com/event/game_record/app/genshin/api/dailyNote`
param: `server` string, `role_id` number

cookieはユーザーがブラウザからコピペする

header

```txt
cookie: cookie
accept: application/json, text/plain, */*
accept-language: en,ja;q=0.9,ja-JP;q=0.8
x-rpc-app_version: 1.5.0
x-rpc-client_type: 5
x-rpc-device_fp: 00000000000
x-rpc-env: default
x-rpc-lang: en-us
x-rpc-language: en-us
// x-rpc-lrsag;
// x-rpc-page: v6.4.1-gr-sea_#/ys
x-rpc-platform: 4
```

レスポンス

```ts
export interface ArchonQuestProgress {
  list: unknown[];
  isOpenArchonQuest: boolean;
  isFinishAllMainline: boolean;
  isFinishAllInterchapter: boolean;
  wikiUrl: string;
}

export enum AttendanceRewardStatus {
  FinishedNonReward = "AttendanceRewardStatusFinishedNonReward",
  Forbid = "AttendanceRewardStatusForbid",
  Invalid = "AttendanceRewardStatusInvalid",
  TakenAward = "AttendanceRewardStatusTakenAward",
  Unfinished = "AttendanceRewardStatusUnfinished",
  WaitTaken = "AttendanceRewardStatusWaitTaken",
}

export interface AttendanceReward {
  status: AttendanceRewardStatus;
  progress: number;
}

export enum TaskRewardStatus {
  Finished = "TaskRewardStatusFinished",
  Invalid = "TaskRewardStatusInvalid",
  TakenAward = "TaskRewardStatusTakenAward",
  Unfinished = "TaskRewardStatusUnfinished",
}

export interface TaskReward {
  status: TaskRewardStatus;
}

export interface DailyTask {
  totalNum: number;
  finishedNum: number;
  isExtraTaskRewardReceived: boolean;
  taskRewards: TaskReward[];
  attendanceRewards: AttendanceReward[];
  attendanceVisible: boolean;
  storedAttendance: string;
  storedAttendanceRefreshCountdown: number;
}

export interface RecoveryTime {
  day: number;
  hour: number;
  minute: number;
  second: number;
  reached: boolean;
}

export interface Transformer {
  obtained: boolean;
  recoveryTime: RecoveryTime;
  wiki: string;
  noticed: boolean;
  latestJobId: string;
}

export enum ExpeditionStatus {
  Finished = "Finished",
  Ongoing = "Ongoing",
}

export interface Expedition {
  avatarSideIcon: string;
  status: ExpeditionStatus;
  remainedTime: string;
}

export interface DailyNote {
  currentResin: number; //use
  maxResin: number; // use
  resinRecoveryTime: string; // use
  finishedTaskNum: number;
  totalTaskNum: number;
  isExtraTaskRewardReceived: boolean;
  remainResinDiscountNum: number;
  resinDiscountNumLimit: number;
  currentExpeditionNum: number;
  maxExpeditionNum: number;
  expeditions: Expedition[];
  currentHomeCoin: number;
  maxHomeCoin: number;
  homeCoinRecoveryTime: string;
  calendarUrl: string; // ignore
  transformer: Transformer; // ignore
  dailyTask: DailyTask;
  archonQuestProgress: ArchonQuestProgress; // ignore
}

export interface DailyNoteResponse {
  retcode: number;
  message: string;
  data: DailyNote;
}
```

## 前提知識

`resin`は8分で1回復する。ゲーム内でユーザーが使用すると減る。回復させることもある。回復させた時は上限を超せる。

## 処理

1. n分(10？)に1回取得する
2. 溢れ始めた時間は`resinRecoveryTime`から計算する
3. 取得した数値とキャッシュの数値を照合して変化を測定
4. 上限に達した理論上の時間と最後に溢れていた時間から溢れて無駄になったresinを計算する

## メニューバー

cookie追加前, cookie expired: ダメそうな表示
resin溢れ前: `{current resin} / {max resin} {resin icon}`
resin 溢れ中: `{trash can icon} {wasted resin} {resin icon}`

クリックでアプリメイン画面を表示する

## メイン画面

まだ考えてないけどresponseのデータを整形して表示する予定
下に`preference`と`quit`ボタンを置く

## preference

textボックス置いてcookie登録、それ以外は未定
