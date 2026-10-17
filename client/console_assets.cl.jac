"""Bundled local Figma assets; Vite resolves URLs for dev and production."""
import from "@jac-client/assets/figma/imgLineLineAH.svg" { default as imgLineLineAH }
import from "@jac-client/assets/figma/imgLineLineHW.svg" { default as imgLineLineHW }
import from "@jac-client/assets/figma/imgLineLineAL.svg" { default as imgLineLineAL }
import from "@jac-client/assets/figma/imgLineLineLO.svg" { default as imgLineLineLO }
import from "@jac-client/assets/figma/imgLineLineBD.svg" { default as imgLineLineBD }
import from "@jac-client/assets/figma/imgLineLineDP.svg" { default as imgLineLineDP }
import from "@jac-client/assets/figma/imgLineLineBHm.svg" { default as imgLineLineBHm }
import from "@jac-client/assets/figma/imgLineLineRC.svg" { default as imgLineLineRC }
import from "@jac-client/assets/figma/imgLineLineCLt.svg" { default as imgLineLineCLt }
import from "@jac-client/assets/figma/imgLineTieBH.svg" { default as imgLineTieBH }
import from "@jac-client/assets/figma/imgLineTieBA.svg" { default as imgLineTieBA }
import from "@jac-client/assets/figma/imgLineTieRA.svg" { default as imgLineTieRA }
import from "@jac-client/assets/figma/imgEllipse.svg" { default as imgEllipse }
import from "@jac-client/assets/figma/imgEllipse1.svg" { default as imgEllipse1 }
import from "@jac-client/assets/figma/imgEllipse2.svg" { default as imgEllipse2 }
import from "@jac-client/assets/figma/imgEllipse3.svg" { default as imgEllipse3 }

glob:pub image_urls: dict[str, str] = {
    "imgLineLineAH": imgLineLineAH as str,
    "imgLineLineHW": imgLineLineHW as str,
    "imgLineLineAL": imgLineLineAL as str,
    "imgLineLineLO": imgLineLineLO as str,
    "imgLineLineBD": imgLineLineBD as str,
    "imgLineLineDP": imgLineLineDP as str,
    "imgLineLineBHm": imgLineLineBHm as str,
    "imgLineLineRC": imgLineLineRC as str,
    "imgLineLineCLt": imgLineLineCLt as str,
    "imgLineTieBH": imgLineTieBH as str,
    "imgLineTieBA": imgLineTieBA as str,
    "imgLineTieRA": imgLineTieRA as str,
    "imgEllipse": imgEllipse as str,
    "imgEllipse1": imgEllipse1 as str,
    "imgEllipse2": imgEllipse2 as str,
    "imgEllipse3": imgEllipse3 as str
};
