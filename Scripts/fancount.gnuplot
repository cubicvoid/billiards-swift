set terminal png large size 1200,1200
set datafile separator ","
set output "fancount-4.png"
set grid
set key off
set timestamp ""
set key default
#set key box
#set key ins vert
#set key left top
set xlabel "<--- X --->"
set ylabel "<--- Y --->"
set size ratio 1
set timestamp

set style line 1 lc rgb '#bbbbee' pt 6 ps 0.2
set style line 2 lc rgb '#9999cc' pt 6 ps 0.2
set style line 3 lc rgb '#8888bb' pt 6 ps 0.2
set style line 4 lc rgb '#7777aa' pt 6 ps 0.2
set style line 5 lc rgb '#666699' pt 6 ps 0.2
set style line 6 lc rgb '#555588' pt 6 ps 0.2
set style line 7 lc rgb '#444477' pt 6 ps 0.2
set style line 8 lc rgb '#333366' pt 6 ps 0.2
set style line 9 lc rgb '#222255' pt 6 ps 0.2
set style line 10 lc rgb '#111144' pt 6 ps 0.2
set style line 11 lc rgb '#BB0000' pt 6 ps 0.2

set xrange [0:0.5]
set yrange [0:0.5]
set object 1 circle at 0.5,0 size 0.5 behind
plot \
  "Data/fancount-4.csv" with points ls 5

quit
