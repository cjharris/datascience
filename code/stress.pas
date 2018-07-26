program stress (input, output);
  const
    mi = 1;
    h = 467 { cm };
    es = 7E11 { dyne/cm^2 };
    ts = 0.015 { cm };
    vs = 0.17;
  type
    dim = array [1..100] of real;
  var
    pos, disp : dim;
    mc, r, sigma, d : real;
    i, n : integer;
  procedure indata;
    begin
      write('What was the film thickness [cm] ? ');
      readln(d);
      writeln;
      write('How many data points ? ');
      readln(n);
      writeln;
      writeln('Enter pos(i), then disp(i):');
      for i := 1 to n do
        readln(pos[i], disp[i]);
    end; { indata }
  procedure outdata;
    begin
      writeln;
      writeln('mc    = ',mc);
      writeln('r     = ',r,' cm');
      writeln('sigma = ',sigma,' dyne/cm^2');
    end; { outdata }
  function slope (var x, y : dim; var n : integer) : real;
    var
      sx, sy, s1, s2, a, b : real;
      i : integer;
    begin
      sx := 0;
      sy := 0;
      s1 := 0;
      s2 := 0;
      for i := 1 to n do
        begin
          sx := sx + x[i]/n;
          sy := sy + y[i]/n;
        end; { for }
      for i := 1 to n do
        begin
          s1 := s1 + y[i]*(x[i] - sx);
          s2 := s2 + sqr(x[i] - sx);
        end; { for }
      a := s1/s2;
      b := sy - a*sx;
      slope := a;
    end; { slope }
  begin
    indata;
    mc := slope(pos,disp,n) - mi;
    r := 2*h/mc;
    sigma := es*sqr(ts)/(1 - sqr(vs))/6/r/d;
    outdata;
  end. { stress }
