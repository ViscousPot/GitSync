import 'package:GitSync/api/remote_censor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('censorRemote', () {
    test('keeps the scheme, the slashes and a trailing .git', () {
      expect(censorRemote('https://github.com/ViscousTests/Cybersecurity-Notes.git'), 'https://**********/************/*******************.git');
    });

    test('keeps the scheme when there is no .git suffix', () {
      expect(censorRemote('https://github.com/a/b'), 'https://**********/*/*');
    });

    test('masks embedded credentials', () {
      final censored = censorRemote('https://user:ghp_secrettoken@github.com/owner/repo.git');
      expect(censored.contains('ghp_secrettoken'), isFalse);
      expect(censored.startsWith('https://'), isTrue);
      expect(censored.endsWith('.git'), isTrue);
    });

    test('handles an scp style ssh remote', () {
      expect(censorRemote('git@github.com:owner/repo.git'), '********************/****.git');
    });

    test('empty input is left alone', () {
      expect(censorRemote('   '), '');
    });
  });

  group('censorRemotesIn', () {
    test('censors a remote inside an error message', () {
      final censored = censorRemotesIn('failed to resolve address for https://github.com/Owner/Secret-Repo.git: no route');
      expect(censored.contains('Secret-Repo'), isFalse);
      expect(censored.contains('failed to resolve address for'), isTrue);
      expect(censored.contains('no route'), isTrue);
    });

    test('censors an scp style remote inside a line', () {
      final censored = censorRemotesIn('remote "origin" is git@gitlab.com:team/private-notes.git now');
      expect(censored.contains('private-notes'), isFalse);
      expect(censored.contains('now'), isTrue);
    });

    test('leaves api endpoints alone', () {
      const line = 'POST https://api.github.com/repos/ViscousPot/GitSync/issues failed';
      expect(censorRemotesIn(line), line);
    });

    test('leaves a deep web link alone', () {
      const line = 'see https://github.com/ViscousPot/GitSync/wiki/Sync-Options';
      expect(censorRemotesIn(line), line);
    });

    test('keeps trailing sentence punctuation outside the mask', () {
      final censored = censorRemotesIn('cloning https://github.com/Owner/Repo, then syncing');
      expect(censored.endsWith(', then syncing'), isTrue);
      expect(censored.contains('Owner'), isFalse);
    });

    test('censors every remote in a multi line block', () {
      final censored = censorRemotesIn('url = https://github.com/a/one.git\nurl = https://github.com/b/two.git');
      expect(censored.contains('one'), isFalse);
      expect(censored.contains('two'), isFalse);
      expect(censored.split('\n').length, 2);
    });

    test('text with no url is unchanged', () {
      const line = 'Push successful';
      expect(censorRemotesIn(line), line);
    });
  });
}
