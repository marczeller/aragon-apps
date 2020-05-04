const ACTIONS_STATE = {
  SUBMITTED: 0,
  CHALLENGED: 1,
  CLOSED: 2
}

const DELAY_STATE = {
  SCHEDULED: 0,
  PAUSED: 1,
  FAST_FORWARDED: 2,
  EXECUTED: 3,
  STOPPED: 4,
}

const CHALLENGES_STATE = {
  WAITING: 0,
  SETTLED: 1,
  DISPUTED: 2,
  REJECTED: 3,
  ACCEPTED: 4,
  VOIDED: 5
}

const RULINGS = {
  MISSING: 0,
  REFUSED: 2,
  IN_FAVOR_OF_SUBMITTER: 3,
  IN_FAVOR_OF_CHALLENGER: 4,
}

module.exports = {
  RULINGS,
  DELAY_STATE,
  ACTIONS_STATE,
  CHALLENGES_STATE
}
