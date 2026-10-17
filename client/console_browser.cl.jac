"""Browser lifecycle helpers. No timers, polling, or animation-driven React state."""
import from react { useEffect }
import from "@jac-client/assets/fonts/FiraSans-Regular.ttf" { default as sansRegular }
import from "@jac-client/assets/fonts/FiraSans-Medium.ttf" { default as sansMedium }
import from "@jac-client/assets/fonts/FiraSans-SemiBold.ttf" { default as sansSemibold }
import from "@jac-client/assets/fonts/FiraCode.ttf" { default as codeFont }

glob fonts_started: bool = False;

def bundled_font_url(url: str) -> str {
    # Jac 0.16.7 serves the Vite dist directory at /static, while Vite's
    # default build base emits flat root-relative font URLs. Dev URLs remain intact.
    built_names = ["/FiraSans-Regular.ttf", "/FiraSans-Medium.ttf", "/FiraSans-SemiBold.ttf", "/FiraCode.ttf"];
    return "/static" + url if url in built_names else url;
}

async def load_fonts() -> None {
    global fonts_started;
    if fonts_started { return; }
    fonts_started = True;
    browser: any = window;
    for (family, url, weight) in [("Fira Sans", sansRegular as str, "400"), ("Fira Sans", sansMedium as str, "500"), ("Fira Sans", sansSemibold as str, "600"), ("Fira Code", codeFont as str, "300 700")] {
        face: any = new(browser.FontFace as type, family, "url(" + bundled_font_url(url) + ")", {"weight": weight, "display": "swap"});
        try { loaded = await face.load(); browser.document.fonts.add(loaded); }
        except Exception { fonts_started = False; }
    }
}

def:pub use_console_layout() -> int {
    browser: any = window;
    has mode: int = 2 if (browser.innerWidth as int) >= 1240 else 1 if (browser.innerWidth as int) >= 700 else 0;
    useEffect(lambda {
        desktop = browser.matchMedia("(min-width: 1240px)");
        tablet = browser.matchMedia("(min-width: 700px)");
        update = lambda { mode = 2 if desktop.matches else 1 if tablet.matches else 0; };
        desktop.addEventListener("change", update);
        tablet.addEventListener("change", update);
        body = browser.document.body;
        margin = body.style.margin;
        body.style.margin = "0";
        load_fonts();
        return lambda {
            desktop.removeEventListener("change", update);
            tablet.removeEventListener("change", update);
            body.style.margin = margin;
        };
    }, []);
    return mode;
}

def:pub use_snapshot_motion(example: str) -> None {
    browser: any = window;
    useEffect(lambda {
        preference = browser.matchMedia("(prefers-reduced-motion: reduce)");
        element = browser.document.getElementById("snapshot-status");
        animation: any = None;
        if element and not preference.matches {
            animation = element.animate([{"opacity": 0.55}, {"opacity": 1}], {"duration": 160, "easing": "ease-out"});
        }
        stop = lambda { if animation { animation.cancel(); } };
        preference.addEventListener("change", stop);
        return lambda { stop(); preference.removeEventListener("change", stop); };
    }, [example]);
}
