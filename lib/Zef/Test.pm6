use Zef;

class Zef::Test does Pluggable {
    method test($path, :@includes, Supplier :$logger) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        my $tester = self.plugins.first(*.test-matcher($path));
        die "No testing backend available" unless ?$tester;

        my $stdmerge;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => TEST, phase => START, payload => self, message => "Testing with plugin: {$tester.^name}" });
            $tester.stdout.Supply.grep(*.defined).act: -> $out { $stdmerge ~= $out; $logger.emit({ level => VERBOSE, stage => TEST, phase => LIVE, message => $out }) }
            $tester.stderr.Supply.grep(*.defined).act: -> $err { $stdmerge ~= $err; $logger.emit({ level => ERROR,   stage => TEST, phase => LIVE, message => $err }) }
        }

        my @got = try $tester.test($path, :@includes);

        $tester.stdout.done;
        $tester.stderr.done;

        @got does role :: { method Str { $stdmerge } }; # boolify for pass/fail, stringify for report

        @got;
    }
}
