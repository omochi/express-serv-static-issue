#!/bin/bash
set -ueo pipefail
script_dir=$(cd "$(dirname "$0")"; pwd)
cd "$script_dir"

image_width=64
image_height=64
rect_width=10
rect_height=10
rect_num=10

get_rand(){
	local rand
	rand=$(od -vAn -N4 -tu4 < /dev/urandom)
	echo $(( $rand % $1 ))
}

get_rand_color(){
	local r
	local g
	local b
	local a
	r=$(get_rand 256)
	g=$(get_rand 256)
	b=$(get_rand 256)
	a=$(printf "%03d" $(get_rand 101))

	echo "rgba($r, $g, $b, "${a:0:1}.${a:1}")"
}

draw_random_rect(){
	local x
	local y
	local w=$rect_width
	local h=$rect_height
	x=$(( $(get_rand $(($image_width+$w)) ) - $w ))
	y=$(( $(get_rand $(($image_height+$h)) ) - $h ))
	command="$command -fill \"$(get_rand_color)\" -stroke \"$(get_rand_color)\" -draw \"rectangle $x,$y $((x+$w)),$((y+$h))\""
}

draw_text(){
	command="$command -fill \"rgb(255,255,255)\" -stroke none"
	command="$command -pointsize 10 -gravity center -draw \"text 0,0 '$1'\""
}

dir=static/img

gen_image(){
	local index=$1
	local i
	echo "gen_image $index"

	command="convert -size ${image_width}x${image_height} xc:'rgba(0,0,0,0)' -fill white -strokewidth 4"

	for ((i=0;i<$rect_num;i++)) ; do
		draw_random_rect
	done

	local name
	name=$(printf "%03d" "$index")
	draw_text "$name"

	command="$command PNG32:./$dir/$name.png"

	eval "$command"
}


mkdir -p $dir
for ((i=0;i<30;i++)); do
	image_width=$((4 + $(get_rand 300) ))
	image_height=$((4 + $(get_rand 300) ))
	rect_width=$((10 + $(get_rand 100) ))
	rect_height=$((10 + $(get_rand 100) ))
	rect_num=$(get_rand 30)
	gen_image $i
done


