#!/usr/bin/env perl6

role Pluggable {
  method plugins(:$module, :$plugin = 'Plugins', :$pattern = / '.pm6' $ /){
    my @list;
    my $class = "{$module:defined ?? $module !! ::?CLASS.^name}";
    $class   ~~ s:g/'::'/\//;
    for (@*INC) -> $dir, {
      try {
        my Str $start = "{$dir.Str.IO.path}/$class/$plugin".IO.path.absolute.Str;
        for self!search($start, base => $start.chars + 1, baseclass => "{$class}::{$plugin}::", pattern => $pattern) -> $t {
          try {
            my $m = $t;
            $m ~~ s:g/\//::/;
            require ::("$m");
            @list.push($m);
          };
        }
        #CATCH { .resume; }
      }
    };
    return @list;
  }

  method !search(Str $dir, Int $recursion = 10, :$baseclass, :$base, :$pattern){ #default to 10 iterations deep
    return if $recursion < 0 || $dir.IO !~~ :d;

    my @r;
    for dir($dir) -> $f {
      try { 
        if $f.IO ~~ :d {
          for self!search($f.absolute.Str, $recursion - 1, :$base, :$baseclass, :$pattern) -> $d {
            @r.push($d);
          };
        }
#        CATCH { .resume; }
      };
      my $modulename = $f.absolute.Str.\
                          substr($base).\
                          subst($pattern, '');
      $modulename   ~~ s:g/ [ '/' | '\\' ] /::/;
      @r.push("$baseclass$modulename") if $f.IO ~~ :f && $f.basename.match($pattern);
    }
    return @r;
  }
}
