p5-Google-Cloud-Speech
======================
This Perl module allows developers to convert audio to text by applying powerful neural network models.

- [Google Cloud Speech API documentation](https://cloud.google.com/speech/docs)

## Quick Start
```sh
$ cpanm install Google::Cloud::Speech
```

## Authentication

This library uses Service Account credentials to connect to Google Cloud services.

For more details visit the [Authentication Guide](https://googlecloudplatform.github.io/google-cloud-ruby/#/docs/google-cloud-speech/guides/authentication).

## Example

### Asynchronous speech recognition

```perl

use Google::Cloud::Speech;
use Data::Dumper;

my $speech = Google::Cloud::Speech->new(
    file    => 'test.wav',
    api_key => 'XXXXXXXXXXXX'
);

my $operation = $speech->asyncrecognize();
my $is_done = $operation->is_done;

until($is_done) {
    if ($is_done = $operation->is_done) {
        print Dumper $operation->results;
    }
}
```

### Synchronous speech recognition

```perl

use Google::Cloud::Speech;
use Data::Dumper;

my $speech = Google::Cloud::Speech->new(
    file    => 'test.wav',
    api_key => 'XXXXXXXXXXXX'
);

my $operation = $speech->syncrecognize();
print Dumper $operations->results;
```

COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2017 by Prajith P

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

