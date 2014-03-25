#!perl

use strict;
use warnings;
use Encode qw( encode_utf8 );
use JSON qw( to_json from_json );
use Plack::Builder;
use Plack::Request;
use Text::Xslate;
use TwitterURL;

my $tx   = Text::Xslate->new;
my $turl = TwitterURL->new;

my $app = sub {
    my $env  = shift;
    my $req  = Plack::Request->new($env);
    my $path = $req->path_info;

    if ( not $path or $path eq '/' ) {
        return return_root($req);
    }
    elsif ( $path eq '/list' ) {
        return return_list($req);
    }
    elsif ( $path eq '/count' ) {
        return return_count($req);
    }
    elsif ( $path eq '/delete' ) {
        return return_delete($req);
    }
    elsif ( $path eq '/save' ) {
        return return_save($req);
    }
    else {
        [ 404, [ "Content-Type" => "text/plain" ], ["404 Not Found"] ];
    }
};

builder {
    enable "Plack::Middleware::ParseSimpleJSON";
    $app;
};

sub return_root {
    my $req = shift;
    my $res = $req->new_response(200);
    $res->content_type('text/html; charset=UTF-8');
    $res->body( render_root() );
    $res->finalize;
}

sub return_list {
    my $req = shift;
    my $width  = $req->param('width');
    my $status = $req->param('status');
    $status = 'saved' eq $status ? 2 : 1;
    my $limit = int( $width / 150 ) + 1;
    my $res   = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_list( limit => $limit, status => $status ) );
    $res->finalize;
}

sub return_count {
    my $req = shift;
    my $status = $req->param('status');
    $status = 'saved' eq $status ? 2 : 1;
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_count( status => $status ) );
    $res->finalize;
}

sub return_delete {
    my $req = shift;
    my $id  = $req->param('id');
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_delete($id) );
    $res->finalize;
}

sub return_save {
    my $req = shift;
    my $id  = $req->param('id');
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_save($id) );
    $res->finalize;
}

sub render_root {
    my $vars = $turl->select_twitter_url(
        order_by => 'id',
        limit    => 5000,
    );
    return encode_utf8 $tx->render( 'list.tx', { url_list => $vars } );
}

sub render_list {
    my %args = @_;
    my $vars = $turl->select_twitter_url(
        order_by => 'id',
        limit    => $args{limit},
        where    => {
            status => $args{status},
        },
    );
    return to_json( $vars, { utf8 => 1, pretty => 1 } );
}

sub render_count {
    my %args = @_;
    my $vars = $turl->select_count(
        where    => {
            status => $args{status},
        },
    );
    return to_json( $vars, { utf8 => 1, pretty => 1 } );
}

sub render_delete {
    my $id     = shift;
    my $result = $turl->delete_id($id);
    if ($result) {
        my $ok = { result => 'ok' };
        return to_json( $ok, { utf8 => 1, pretty => 1 } );
    }
    else {
        my $ng = {
            result  => 'ng',
            message => $turl->errstr,
        };
        return to_json( $ng, { utf8 => 1, pretty => 1 } );
    }
}

sub render_save {
    my $id     = shift;
    my $result = $turl->save_id($id);
    if ($result) {
        my $ok = { result => 'ok' };
        return to_json( $ok, { utf8 => 1, pretty => 1 } );
    }
    else {
        my $ng = {
            result  => 'ng',
            message => $turl->errstr,
        };
        return to_json( $ng, { utf8 => 1, pretty => 1 } );
    }
}
