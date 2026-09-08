module rotate_around(a, v, center) {
    translate(center)
        rotate(a, v)
            translate(-center)
                children();
}
