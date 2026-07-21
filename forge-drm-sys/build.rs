fn main() {
    // Link libliftoff
    pkg_config::Config::new()
        .atleast_version("0.5")
        .probe("libliftoff")
        .expect("Failed to find libliftoff >= 0.5");

    // Link libdisplay-info
    pkg_config::Config::new()
        .atleast_version("0.3")
        .probe("libdisplay-info")
        .expect("Failed to find libdisplay-info >= 0.3");

    // Link libdrm
    pkg_config::Config::new()
        .atleast_version("2.4.120")
        .probe("libdrm")
        .expect("Failed to find libdrm");

    // Link libgbm
    pkg_config::Config::new()
        .atleast_version("22.0")
        .probe("gbm")
        .expect("Failed to find libgbm");

    // Link libseat
    pkg_config::Config::new()
        .atleast_version("0.2")
        .probe("libseat")
        .expect("Failed to find libseat");
}
