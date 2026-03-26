const Map<String, String> standardReactions = {
  '+1': '\u{1F44D}',
  '-1': '\u{1F44E}',
  'laugh': '\u{1F604}',
  'hooray': '\u{1F389}',
  'confused': '\u{1F615}',
  'heart': '\u{2764}\u{FE0F}',
  'rocket': '\u{1F680}',
  'eyes': '\u{1F440}',
};

// GitHub GraphQL uses uppercase names
const Map<String, String> githubReactionNames = {
  '+1': 'THUMBS_UP',
  '-1': 'THUMBS_DOWN',
  'laugh': 'LAUGH',
  'hooray': 'HOORAY',
  'confused': 'CONFUSED',
  'heart': 'HEART',
  'rocket': 'ROCKET',
  'eyes': 'EYES',
};

const Map<String, String> githubReactionNamesReverse = {
  'THUMBS_UP': '+1',
  'THUMBS_DOWN': '-1',
  'LAUGH': 'laugh',
  'HOORAY': 'hooray',
  'CONFUSED': 'confused',
  'HEART': 'heart',
  'ROCKET': 'rocket',
  'EYES': 'eyes',
};

// GitLab uses shortcode-style names
const Map<String, String> gitlabReactionNames = {
  '+1': 'thumbsup',
  '-1': 'thumbsdown',
  'laugh': 'laughing',
  'hooray': 'tada',
  'confused': 'confused',
  'heart': 'heart',
  'rocket': 'rocket',
  'eyes': 'eyes',
};

const Map<String, String> gitlabReactionNamesReverse = {
  'thumbsup': '+1',
  'thumbsdown': '-1',
  'laughing': 'laugh',
  'tada': 'hooray',
  'confused': 'confused',
  'heart': 'heart',
  'rocket': 'rocket',
  'eyes': 'eyes',
};
