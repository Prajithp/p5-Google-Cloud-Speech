package Google::Cloud::Speech;

use Mojo::Base -base;
use Mojo::UserAgent;
use MIME::Base64;
use Mojo::File;
use Carp;

$Google::Cloud::Speech::VERSION = '0.02';

has api_key => sub { croak 'invalid api key'; };
has ua      => sub { Mojo::UserAgent->new() };
has file    => sub { croak 'you must specify the audio file'; };
has rate    => '16000';
has lang    => 'en-IN';
has encoding => 'linear16';
has url      => 'https://speech.googleapis.com/v1';
has async_id => undef;
has results  => undef;

has config => sub {
    my $self = shift;

    return {
        encoding        => $self->encoding,
        sampleRateHertz => $self->rate,
        languageCode    => $self->lang,
        profanityFilter => 'false',
    };
};

sub syncrecognize {
    my $self = shift;

    my $audio_raw = Mojo::File->new( $self->file )->slurp();

    my $audio = { "content" => encode_base64( $audio_raw, "" ) };
    my $header = { 'Content-Type' => "application/json" };

    my $hash_ref = {
        config => $self->config,
        audio  => $audio,
    };

    my $url = $self->url . "/speech:recognize?key=" . $self->api_key;
    my $tx = $self->ua->post( $url => $header => json => $hash_ref );

    my $response = $self->handle_errors($tx)->json;
    if ( my $results = $response->{'results'} ) {
        return $self->results($results);
    }
    return $self->results([]);

}

sub asyncrecognize {
    my $self = shift;

    my $audio_raw = Mojo::File->new( $self->file )->slurp();
    my $audio     = { "content" => encode_base64( $audio_raw, "" ) };
    my $header    = { 'Content-Type' => "application/json" };

    my $hash_ref = {
        config => $self->config,
        audio  => $audio,
    };

    my $url
        = $self->url . "/speech:longrunningrecognize?key=" . $self->api_key;
    my $tx = $self->ua->post( $url => $header => json => $hash_ref );

    my $res = $self->handle_errors($tx)->json;
    if ( my $name = $res->{'name'} ) {
        $self->async_id($name);

        return $self;
    }

    croak 'there was an error';
}

sub is_done {
    my $self = shift;

    my $async_id = $self->async_id;
    return unless $async_id;

    my $url = $self->url . "/operations/" . $async_id . "?key=" . $self->api_key;
    my $tx = $self->ua->get($url);

    my $res     = $self->handle_errors($tx)->json;
    my $is_done = $res->{'done'};

    if ($is_done) {
        $self->{'results'} = $res->{'response'}->{'results'};
        return 1;
    }

    return 0;
}

sub handle_errors {
    my ( $self, $tx ) = @_;
    my $res = $tx->res;

    unless ( $tx->success ) {
        my $error_ref = $tx->error;
        croak( "invalid response: " . $error_ref->{'message'} );
    }

    return $res;
}

1;

=encoding utf8

=head1 NAME

Google::Cloud::Speech - An interface to Google cloud speech service

=head1 SYNOPSIS

	use Data::Dumper;
	use Google::Cloud::Speech;

	my $speech = Google::Cloud::Speech->new(
		file    => 'test.wav',
		api_key => 'xxxxx'
	);

	# long running process
	my $operation = $speech->asyncrecognize();
	my $is_done = $operation->is_done;
	until($is_done) {
		if ($is_done = $operation->is_done) {
			print Dumper $operation->results;
		}
	}

=head1 DESCRIPTION

This module lets you access Google cloud speech service.

=head1 ATTRIBUTES

=head2 C<api_key>

	my $key = $speech->api_key;
	my $key = $speech->api_key('xxxxNEWKEYxxxx');
	Cloud Speech API key, used for authanitication.  Usually set using L</new>.
	
	See https://cloud.google.com/docs/authentication for more details about API authentication.

=head2 encoding

	my $encoding = $speech->encoding('linear16');

	Encoding of audio data to be recognized.
	Acceptable values are:
        
		* linear16 - Uncompressed 16-bit signed little-endian samples.
			(LINEAR16)
		* flac - The [Free Lossless Audio
			Codec](http://flac.sourceforge.net/documentation.html) encoding.
			Only 16-bit samples are supported. Not all fields in STREAMINFO
			are supported. (FLAC)
		* mulaw - 8-bit samples that compand 14-bit audio samples using
			G.711 PCMU/mu-law. (MULAW)
		* amr - Adaptive Multi-Rate Narrowband codec. (`sample_rate` must
			be 8000 Hz.) (AMR)
		* amr_wb - Adaptive Multi-Rate Wideband codec. (`sample_rate` must
			be 16000 Hz.) (AMR_WB)
		* ogg_opus - Ogg Mapping for Opus. (OGG_OPUS)
			Lossy codecs do not recommend, as they result in a lower-quality
			speech transcription.
		* speex - Speex with header byte. (SPEEX_WITH_HEADER_BYTE)
        
        
=head2 file
	
	my $file = $speech->file;
	my $file = $speech->('path/to/audio/file.wav');


=head2 lang

	my $lang = $speech->lang('en-IN');

	The language of the supplied audio as a BCP-47 language tag. 
	Example: "en-IN" for English (United States), "en-GB" for English (United
	Kingdom), "fr-FR" for French (France). See Language Support for a list of the currently supported language codes. 
	L<https://cloud.google.com/speech/docs/languages>

=head2 rate

	my $sample_rate = $speech->rate('16000');

	Sample rate in Hertz of the audio data to be recognized. Valid values
	are: 8000-48000. 16000 is optimal. For best results, set the sampling
	rate of the audio source to 16000 Hz. If that's not possible, use the
	native sample rate of the audio source (instead of re-sampling).


=head1 METHODS

=head2 asyncrecognize

	Performs asynchronous speech recognition: 
	receive results via the google.longrunning.Operations interface. 

	my $operation = $speech->asyncrecognize();
	my $is_done = $operation->is_done;
	until($is_done) {
		if ($is_done = $operation->is_done) {
			print Dumper $operation->results;
		}
	}

=head2 is_done

	Checks if the speech-recognition processing of the audio data is complete.
	return 1 when complete, 0 otherwise.

=head2 results

	print Dumper $speech->syncrecognize->results;
	
	returns the converted data as Arrayref.

=head2 syncrecognize

	Performs synchronous speech recognition: receive results after all audio has been sent and processed.
	
	my $operation = $speech->syncrecognize;
	print $operation->results;

=head1 AUTHOR

Prajith NDZ C<prajith@ndimensionz.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, Prajith Ndimensionz.

This is free software, you can redistribute it and/or modify it under
the same terms as Perl language system itself.


=head1 SEE ALSO

=over

=item * L<Google Cloud Speech API| https://cloud.google.com/speech/reference/rest/>

=back

=cut

=head1 DEVELOPMENT

This project is hosted on Github, at
L<https://github.com/Prajithp/p5-google-cloud-speech>

=cut
