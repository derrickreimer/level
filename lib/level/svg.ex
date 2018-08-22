defmodule Level.Svg do
  @moduledoc """
  Functions for manipulating SVG.
  """

  @doc """
  Transforms raw SVGs into elm/svg syntax.
  """
  @spec to_elm(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def to_elm(raw_svg) do
    raw_svg
    |> Floki.parse()
    |> tree_to_elm()
    |> process_elm()
  end

  defp process_elm(nil), do: {:ok, ""}
  defp process_elm(value), do: {:ok, value}

  # Internals

  defp tree_to_elm({node_type, attrs, children}) do
    case cast_type(node_type) do
      nil -> nil
      elm_name -> build_node(elm_name, attrs, children)
    end
  end

  defp tree_to_elm({:comment, _}), do: nil

  defp tree_to_elm([]), do: nil

  defp tree_to_elm(val) when is_binary(val) do
    "text \"#{val}\""
  end

  defp build_node(elm_name, attrs, children) do
    attr_string =
      attrs
      |> Enum.map(&cast_attr/1)
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.join(", ")

    node_string = "#{elm_name} [ #{attr_string} ]"

    if length(children) > 0 do
      child_string =
        children
        |> Enum.map(&tree_to_elm/1)
        |> Enum.filter(&(!is_nil(&1)))
        |> Enum.join(", ")

      "#{node_string} [ #{child_string} ]"
    else
      "#{node_string} []"
    end
  end

  # Elements

  defp cast_type("svg"), do: "svg"
  defp cast_type("foreignObject"), do: "foreignObject"
  defp cast_type("circle"), do: "circle"
  defp cast_type("ellipse"), do: "ellipse"
  defp cast_type("image"), do: "image"
  defp cast_type("line"), do: "line"
  defp cast_type("path"), do: "Svg.path"
  defp cast_type("polygon"), do: "polygon"
  defp cast_type("polyline"), do: "polyline"
  defp cast_type("rect"), do: "rect"
  defp cast_type("use"), do: "use"
  defp cast_type("animate"), do: "animate"
  defp cast_type("animatecolor"), do: "animateColor"
  defp cast_type("animatenotion"), do: "animateMotion"
  defp cast_type("animatetransform"), do: "animateTransform"
  defp cast_type("mpath"), do: "mpath"
  defp cast_type("set"), do: "set"
  defp cast_type("desc"), do: "desc"
  defp cast_type("metadata"), do: "metadata"
  defp cast_type("a"), do: "a"
  defp cast_type("defs"), do: "defs"
  defp cast_type("g"), do: "g"
  defp cast_type("marker"), do: "marker"
  defp cast_type("mask"), do: "mask"
  defp cast_type("pattern"), do: "pattern"
  defp cast_type("switch"), do: "switch"
  defp cast_type("symbol"), do: "symbol"
  defp cast_type("altglyph"), do: "altGlyph"
  defp cast_type("altglyphdef"), do: "altGlyphDef"
  defp cast_type("altglyphitem"), do: "altGlyphItem"
  defp cast_type("glyph"), do: "glyph"
  defp cast_type("glyphref"), do: "glyphRef"
  defp cast_type("textpath"), do: "textPath"
  defp cast_type("text"), do: "text_"
  defp cast_type("tref"), do: "tref"
  defp cast_type("tspan"), do: "tspan"
  defp cast_type("font"), do: "font"
  defp cast_type("lineargradient"), do: "linearGradient"
  defp cast_type("radialgradient"), do: "radialGradient"
  defp cast_type("stop"), do: "stop"
  defp cast_type("feblend"), do: "feBlend"
  defp cast_type("fecolormatrix"), do: "feColorMatrix"
  defp cast_type("fecomponenttransfer"), do: "feComponentTransfer"
  defp cast_type("fecomposite"), do: "feComposite"
  defp cast_type("feconvolvematrix"), do: "feConvolveMatrix"
  defp cast_type("fediffuselighting"), do: "feDiffuseLighting"
  defp cast_type("fedisplacementmap"), do: "feDisplacementMap"
  defp cast_type("feflood"), do: "feFlood"
  defp cast_type("fefunca"), do: "feFuncA"
  defp cast_type("fefuncb"), do: "feFuncB"
  defp cast_type("fefuncg"), do: "feFuncG"
  defp cast_type("fefuncr"), do: "feFuncR"
  defp cast_type("fegaussianblur"), do: "feGaussianBlur"
  defp cast_type("feimage"), do: "feImage"
  defp cast_type("femerge"), do: "feMerge"
  defp cast_type("femergenode"), do: "feMergeNode"
  defp cast_type("femorphology"), do: "feMorphology"
  defp cast_type("feoffset"), do: "feOffset"
  defp cast_type("fespecularlighting"), do: "feSpecularLighting"
  defp cast_type("fetile"), do: "feTile"
  defp cast_type("feturbulence"), do: "feTurbulence"
  defp cast_type("fedistantlight"), do: "feDistantLight"
  defp cast_type("fepointlight"), do: "fePointLight"
  defp cast_type("fespotlight"), do: "feSpotLight"
  defp cast_type("clippath"), do: "clipPath"
  defp cast_type("color-profile"), do: "colorProfile"
  defp cast_type("cursor"), do: "cursor"
  defp cast_type("filter"), do: "filter"
  defp cast_type("style"), do: "style"
  defp cast_type("view"), do: "view"

  # strip titles
  defp cast_type("title"), do: nil
  defp cast_type(_), do: nil

  # Regular attributes

  defp cast_attr({"accent-height", value}), do: build_attr("accentHeight", value)
  defp cast_attr({"accelerate", value}), do: build_attr("accelerate", value)
  defp cast_attr({"additive", value}), do: build_attr("additive", value)
  defp cast_attr({"alphabetic", value}), do: build_attr("alphabetic", value)
  defp cast_attr({"allowreorder", value}), do: build_attr("allowReorder", value)

  defp cast_attr({"amplitude", value}), do: build_attr("amplitude", value)
  defp cast_attr({"arabic-form", value}), do: build_attr("arabicForm", value)
  defp cast_attr({"ascent", value}), do: build_attr("ascent", value)
  defp cast_attr({"attributename", value}), do: build_attr("attributeName", value)
  defp cast_attr({"attributetype", value}), do: build_attr("attributeType", value)
  defp cast_attr({"autoreverse", value}), do: build_attr("autoReverse", value)

  defp cast_attr({"azimuth", value}), do: build_attr("azimuth", value)
  defp cast_attr({"basefrequency", value}), do: build_attr("baseFrequency", value)
  defp cast_attr({"baseprofile", value}), do: build_attr("baseProfile", value)
  defp cast_attr({"bbox", value}), do: build_attr("bbox", value)
  defp cast_attr({"begin", value}), do: build_attr("begin", value)
  defp cast_attr({"bias", value}), do: build_attr("bias", value)
  defp cast_attr({"by", value}), do: build_attr("by", value)
  defp cast_attr({"calcmode", value}), do: build_attr("calcMode", value)

  defp cast_attr({"cap-height", value}), do: build_attr("capHeight", value)
  defp cast_attr({"class", value}), do: build_attr("class", value)
  defp cast_attr({"clippathunits", value}), do: build_attr("clipPathUnits", value)
  defp cast_attr({"contentscripttype", value}), do: build_attr("contentScriptType", value)
  defp cast_attr({"contentstyletype", value}), do: build_attr("contentStyleType", value)
  defp cast_attr({"cx", value}), do: build_attr("cx", value)
  defp cast_attr({"cy", value}), do: build_attr("cy", value)

  defp cast_attr({"d", value}), do: build_attr("d", value)
  defp cast_attr({"decelerate", value}), do: build_attr("decelerate", value)
  defp cast_attr({"descent", value}), do: build_attr("descent", value)
  defp cast_attr({"diffuseconstant", value}), do: build_attr("diffuseConstant", value)
  defp cast_attr({"divisor", value}), do: build_attr("divisor", value)
  defp cast_attr({"dur", value}), do: build_attr("dur", value)
  defp cast_attr({"dx", value}), do: build_attr("dx", value)
  defp cast_attr({"dy", value}), do: build_attr("dy", value)
  defp cast_attr({"edgemode", value}), do: build_attr("edgeMode", value)

  defp cast_attr({"elevation", value}), do: build_attr("elevation", value)
  defp cast_attr({"end", value}), do: build_attr("end", value)
  defp cast_attr({"exponent", value}), do: build_attr("exponent", value)

  defp cast_attr({"externalresourcesrequired", value}),
    do: build_attr("externalResourcesRequired", value)

  defp cast_attr({"filterres", value}), do: build_attr("filterRes", value)
  defp cast_attr({"filterunits", value}), do: build_attr("filterUnits", value)

  defp cast_attr({"format", value}), do: build_attr("format", value)
  defp cast_attr({"from", value}), do: build_attr("from", value)
  defp cast_attr({"fx", value}), do: build_attr("fx", value)
  defp cast_attr({"fy", value}), do: build_attr("fy", value)
  defp cast_attr({"g1", value}), do: build_attr("g1", value)
  defp cast_attr({"g2", value}), do: build_attr("g2", value)
  defp cast_attr({"glyph-name", value}), do: build_attr("glyphName", value)
  defp cast_attr({"glyphref", value}), do: build_attr("glyphRef", value)
  defp cast_attr({"gradienttransform", value}), do: build_attr("gradientTransform", value)

  defp cast_attr({"gradientunits", value}), do: build_attr("gradientUnits", value)
  defp cast_attr({"hanging", value}), do: build_attr("hanging", value)
  defp cast_attr({"height", value}), do: build_attr("height", value)
  defp cast_attr({"horiz-adv-x", value}), do: build_attr("horizAdvX", value)
  defp cast_attr({"horiz-origin-x", value}), do: build_attr("horizOriginX", value)
  defp cast_attr({"horiz-origin-y", value}), do: build_attr("horizOriginY", value)
  defp cast_attr({"id", value}), do: build_attr("id", value)

  defp cast_attr({"ideographic", value}), do: build_attr("ideographic", value)
  defp cast_attr({"in", value}), do: build_attr("in_", value)
  defp cast_attr({"in2", value}), do: build_attr("in2", value)
  defp cast_attr({"intercept", value}), do: build_attr("intercept", value)
  defp cast_attr({"k", value}), do: build_attr("k", value)
  defp cast_attr({"k1", value}), do: build_attr("k1", value)
  defp cast_attr({"k2", value}), do: build_attr("k2", value)
  defp cast_attr({"k3", value}), do: build_attr("k3", value)
  defp cast_attr({"k4", value}), do: build_attr("k4", value)
  defp cast_attr({"kernelmatrix", value}), do: build_attr("kernelMatrix", value)

  defp cast_attr({"kernelunitlength", value}), do: build_attr("kernelUnitLength", value)
  defp cast_attr({"keypoints", value}), do: build_attr("keyPoints", value)
  defp cast_attr({"keysplines", value}), do: build_attr("keySplines", value)
  defp cast_attr({"keytimes", value}), do: build_attr("keyTimes", value)

  defp cast_attr({"lang", value}), do: build_attr("lang", value)
  defp cast_attr({"lengthadjust", value}), do: build_attr("lengthAdjust", value)
  defp cast_attr({"limitingconeangle", value}), do: build_attr("limitingConeAngle", value)
  defp cast_attr({"local", value}), do: build_attr("local", value)

  defp cast_attr({"markerheight", value}), do: build_attr("markerHeight", value)
  defp cast_attr({"markerunits", value}), do: build_attr("markerUnits", value)
  defp cast_attr({"markerwidth", value}), do: build_attr("markerWidth", value)
  defp cast_attr({"maskcontentunits", value}), do: build_attr("maskContentUnits", value)
  defp cast_attr({"maskunits", value}), do: build_attr("maskUnits", value)
  defp cast_attr({"mathematical", value}), do: build_attr("mathematical", value)
  defp cast_attr({"max", value}), do: build_attr("max", value)
  defp cast_attr({"media", value}), do: build_attr("media", value)
  defp cast_attr({"method", value}), do: build_attr("method", value)
  defp cast_attr({"min", value}), do: build_attr("min", value)
  defp cast_attr({"mode", value}), do: build_attr("mode", value)

  defp cast_attr({"name", value}), do: build_attr("name", value)
  defp cast_attr({"numoctaves", value}), do: build_attr("numOctaves", value)

  defp cast_attr({"offset", value}), do: build_attr("offset", value)
  defp cast_attr({"operator", value}), do: build_attr("operator", value)
  defp cast_attr({"order", value}), do: build_attr("order", value)
  defp cast_attr({"orient", value}), do: build_attr("orient", value)
  defp cast_attr({"orientation", value}), do: build_attr("orientation", value)
  defp cast_attr({"origin", value}), do: build_attr("origin", value)
  defp cast_attr({"overline-position", value}), do: build_attr("overlinePosition", value)
  defp cast_attr({"overline-thickness", value}), do: build_attr("overlineThickness", value)

  defp cast_attr({"panose-1", value}), do: build_attr("panose1", value)
  defp cast_attr({"path", value}), do: build_attr("Svg.Attributes.path", value)
  defp cast_attr({"pathlength", value}), do: build_attr("pathLength", value)
  defp cast_attr({"patterncontentunits", value}), do: build_attr("patternContentUnits", value)
  defp cast_attr({"patterntransform", value}), do: build_attr("patternTransform", value)
  defp cast_attr({"patternunits", value}), do: build_attr("patternUnits", value)
  defp cast_attr({"pointorder", value}), do: build_attr("pointOrder", value)
  defp cast_attr({"points", value}), do: build_attr("points", value)
  defp cast_attr({"pointsatx", value}), do: build_attr("pointsAtX", value)
  defp cast_attr({"pointsaty", value}), do: build_attr("pointsAtY", value)
  defp cast_attr({"pointsatz", value}), do: build_attr("pointsAtZ", value)
  defp cast_attr({"preservealpha", value}), do: build_attr("preserveAlpha", value)
  defp cast_attr({"preserveaspectratio", value}), do: build_attr("preserveAspectRatio", value)
  defp cast_attr({"primitiveunits", value}), do: build_attr("primitiveUnits", value)

  defp cast_attr({"r", value}), do: build_attr("r", value)
  defp cast_attr({"radius", value}), do: build_attr("radius", value)
  defp cast_attr({"refx", value}), do: build_attr("refX", value)
  defp cast_attr({"refy", value}), do: build_attr("refY", value)
  defp cast_attr({"rendering-intent", value}), do: build_attr("renderingIntent", value)
  defp cast_attr({"repeatcount", value}), do: build_attr("repeatCount", value)
  defp cast_attr({"repeatdur", value}), do: build_attr("repeatDur", value)
  defp cast_attr({"requiredextensions", value}), do: build_attr("requiredExtensions", value)
  defp cast_attr({"requiredfeatures", value}), do: build_attr("requiredFeatures", value)
  defp cast_attr({"restart", value}), do: build_attr("restart", value)
  defp cast_attr({"result", value}), do: build_attr("result", value)
  defp cast_attr({"rotate", value}), do: build_attr("rotate", value)
  defp cast_attr({"rx", value}), do: build_attr("rx", value)
  defp cast_attr({"ry", value}), do: build_attr("ry", value)

  defp cast_attr({"scale", value}), do: build_attr("scale", value)
  defp cast_attr({"seed", value}), do: build_attr("seed", value)
  defp cast_attr({"slope", value}), do: build_attr("slope", value)
  defp cast_attr({"spacing", value}), do: build_attr("spacing", value)
  defp cast_attr({"specularconstant", value}), do: build_attr("specularConstant", value)
  defp cast_attr({"specularexponent", value}), do: build_attr("specularExponent", value)
  defp cast_attr({"speed", value}), do: build_attr("speed", value)
  defp cast_attr({"spreadmethod", value}), do: build_attr("spreadMethod", value)
  defp cast_attr({"startoffset", value}), do: build_attr("startOffset", value)
  defp cast_attr({"stddeviation", value}), do: build_attr("stdDeviation", value)
  defp cast_attr({"stemh", value}), do: build_attr("stemh", value)
  defp cast_attr({"stemv", value}), do: build_attr("stemv", value)
  defp cast_attr({"stitchtiles", value}), do: build_attr("stitchTiles", value)

  defp cast_attr({"strikethrough-position", value}),
    do: build_attr("strikethroughPosition", value)

  defp cast_attr({"strikethrough-thickness", value}),
    do: build_attr("strikethroughThickness", value)

  defp cast_attr({"string", value}), do: build_attr("string", value)
  defp cast_attr({"style", value}), do: build_attr("style", value)
  defp cast_attr({"surfacescale", value}), do: build_attr("surfaceScale", value)
  defp cast_attr({"systemlanguage", value}), do: build_attr("systemLanguage", value)

  defp cast_attr({"tablevalues", value}), do: build_attr("tableValues", value)
  defp cast_attr({"target", value}), do: build_attr("target", value)
  defp cast_attr({"targetx", value}), do: build_attr("targetX", value)
  defp cast_attr({"targety", value}), do: build_attr("targetY", value)
  defp cast_attr({"textlength", value}), do: build_attr("textLength", value)
  defp cast_attr({"title", value}), do: build_attr("title", value)
  defp cast_attr({"to", value}), do: build_attr("to", value)
  defp cast_attr({"transform", value}), do: build_attr("transform", value)
  defp cast_attr({"type_", value}), do: build_attr("type_", value)

  defp cast_attr({"u1", value}), do: build_attr("u1", value)
  defp cast_attr({"u2", value}), do: build_attr("u2", value)
  defp cast_attr({"underline-position", value}), do: build_attr("underlinePosition", value)
  defp cast_attr({"underline-thickness", value}), do: build_attr("underlineThickness", value)
  defp cast_attr({"unicode", value}), do: build_attr("unicode", value)
  defp cast_attr({"unicode-range", value}), do: build_attr("unicodeRange", value)
  defp cast_attr({"units-per-em", value}), do: build_attr("unitsPerEm", value)

  defp cast_attr({"v-alphabetic", value}), do: build_attr("vAlphabetic", value)
  defp cast_attr({"v-hanging", value}), do: build_attr("vHanging", value)
  defp cast_attr({"v-ideographic", value}), do: build_attr("vIdeographic", value)
  defp cast_attr({"v-mathematical", value}), do: build_attr("vMathematical", value)
  defp cast_attr({"values", value}), do: build_attr("values", value)
  defp cast_attr({"version", value}), do: build_attr("version", value)
  defp cast_attr({"vert-adv-y", value}), do: build_attr("vertAdvY", value)
  defp cast_attr({"vert-origin-x", value}), do: build_attr("vertOriginX", value)
  defp cast_attr({"vert-origin-y", value}), do: build_attr("vertOriginY", value)
  defp cast_attr({"viewbox", value}), do: build_attr("viewBox", value)
  defp cast_attr({"viewtarget", value}), do: build_attr("viewTarget", value)

  defp cast_attr({"width", value}), do: build_attr("width", value)
  defp cast_attr({"widths", value}), do: build_attr("widths", value)

  defp cast_attr({"x", value}), do: build_attr("x", value)
  defp cast_attr({"xheight", value}), do: build_attr("xHeight", value)
  defp cast_attr({"x1", value}), do: build_attr("x1", value)
  defp cast_attr({"x2", value}), do: build_attr("x2", value)
  defp cast_attr({"xchannelselector", value}), do: build_attr("xChannelSelector", value)
  defp cast_attr({"xlinkactuate", value}), do: build_attr("xlinkActuate", value)
  defp cast_attr({"xlinkarcrole", value}), do: build_attr("xlinkArcrole", value)
  defp cast_attr({"xlinkhref", value}), do: build_attr("xlinkHref", value)
  defp cast_attr({"xlinkrole", value}), do: build_attr("xlinkRole", value)
  defp cast_attr({"xlinkshow", value}), do: build_attr("xlinkShow", value)
  defp cast_attr({"xlinktitle", value}), do: build_attr("xlinkTitle", value)
  defp cast_attr({"xlinktype", value}), do: build_attr("xlinkType", value)
  defp cast_attr({"xmlbase", value}), do: build_attr("xmlBase", value)
  defp cast_attr({"xmllang", value}), do: build_attr("xmlLang", value)
  defp cast_attr({"xmlspace", value}), do: build_attr("xmlSpace", value)

  defp cast_attr({"y", value}), do: build_attr("y", value)
  defp cast_attr({"y1", value}), do: build_attr("y1", value)
  defp cast_attr({"y2", value}), do: build_attr("y2", value)
  defp cast_attr({"ychannelselector", value}), do: build_attr("yChannelSelector", value)

  defp cast_attr({"z", value}), do: build_attr("z", value)
  defp cast_attr({"zoomAndPan", value}), do: build_attr("zoomAndPan", value)

  # Presentation attributes

  defp cast_attr({"alignment-baseline", value}), do: build_attr("alignmentBaseline", value)
  defp cast_attr({"baseline-shift", value}), do: build_attr("baselineShift", value)
  defp cast_attr({"clip-path", value}), do: build_attr("clipPath", value)
  defp cast_attr({"clip-rule", value}), do: build_attr("clipRule", value)
  defp cast_attr({"clip", value}), do: build_attr("clip", value)

  defp cast_attr({"color-interpolation-filters", value}),
    do: build_attr("colorInterpolationFilters", value)

  defp cast_attr({"color-interpolation", value}), do: build_attr("colorInterpolation", value)
  defp cast_attr({"color-profile", value}), do: build_attr("colorProfile", value)
  defp cast_attr({"color-rendering", value}), do: build_attr("colorRendering", value)
  defp cast_attr({"color", value}), do: build_attr("color", value)
  defp cast_attr({"cursor", value}), do: build_attr("cursor", value)
  defp cast_attr({"direction", value}), do: build_attr("direction", value)
  defp cast_attr({"display", value}), do: build_attr("display", value)
  defp cast_attr({"dominant-baseline", value}), do: build_attr("dominantBaseline", value)
  defp cast_attr({"enable-background", value}), do: build_attr("enableBackground", value)
  defp cast_attr({"fill-opacity", value}), do: build_attr("fillOpacity", value)
  defp cast_attr({"fill-rule", value}), do: build_attr("fillRule", value)
  defp cast_attr({"fill", value}), do: build_attr("fill", value)
  defp cast_attr({"filter", value}), do: build_attr("filter", value)
  defp cast_attr({"flood-color", value}), do: build_attr("floodColor", value)
  defp cast_attr({"flood-opacity", value}), do: build_attr("floodOpacity", value)
  defp cast_attr({"font-family", value}), do: build_attr("fontFamily", value)
  defp cast_attr({"font-size-adjust", value}), do: build_attr("fontSizeAdjust", value)
  defp cast_attr({"font-size", value}), do: build_attr("fontSize", value)
  defp cast_attr({"font-stretch", value}), do: build_attr("fontStretch", value)
  defp cast_attr({"font-style", value}), do: build_attr("fontStyle", value)
  defp cast_attr({"font-variant", value}), do: build_attr("fontVariant", value)
  defp cast_attr({"font-weight", value}), do: build_attr("fontWeight", value)

  defp cast_attr({"glyph-orientation-horizontal", value}),
    do: build_attr("glyphOrientationHorizontal", value)

  defp cast_attr({"glyph-orientation-vertical", value}),
    do: build_attr("glyphOrientationVertical", value)

  defp cast_attr({"image-rendering", value}), do: build_attr("imageRendering", value)
  defp cast_attr({"kerning", value}), do: build_attr("kerning", value)
  defp cast_attr({"letter-spacing", value}), do: build_attr("letterSpacing", value)
  defp cast_attr({"lighting-color", value}), do: build_attr("lightingColor", value)
  defp cast_attr({"marker-end", value}), do: build_attr("markerEnd", value)
  defp cast_attr({"marker-mid", value}), do: build_attr("markerMid", value)
  defp cast_attr({"marker-start", value}), do: build_attr("markerStart", value)
  defp cast_attr({"mask", value}), do: build_attr("mask", value)
  defp cast_attr({"opacity", value}), do: build_attr("opacity", value)
  defp cast_attr({"overflow", value}), do: build_attr("overflow", value)
  defp cast_attr({"pointer-events", value}), do: build_attr("pointerEvents", value)
  defp cast_attr({"shape-rendering", value}), do: build_attr("shapeRendering", value)
  defp cast_attr({"stop-color", value}), do: build_attr("stopColor", value)
  defp cast_attr({"stop-opacity", value}), do: build_attr("stopOpacity", value)
  defp cast_attr({"stroke-dasharray", value}), do: build_attr("strokeDasharray", value)
  defp cast_attr({"stroke-dashoffset", value}), do: build_attr("strokeDashoffset", value)
  defp cast_attr({"stroke-linecap", value}), do: build_attr("strokeLinecap", value)
  defp cast_attr({"stroke-linejoin", value}), do: build_attr("strokeLinejoin", value)
  defp cast_attr({"stroke-miterlimit", value}), do: build_attr("strokeMiterlimit", value)
  defp cast_attr({"stroke-opacity", value}), do: build_attr("strokeOpacity", value)
  defp cast_attr({"stroke-width", value}), do: build_attr("strokeWidth", value)
  defp cast_attr({"stroke", value}), do: build_attr("stroke", value)
  defp cast_attr({"text-anchor", value}), do: build_attr("textAnchor", value)
  defp cast_attr({"text-decoration", value}), do: build_attr("textDecoration", value)
  defp cast_attr({"text-rendering", value}), do: build_attr("textRendering", value)
  defp cast_attr({"unicode-bidi", value}), do: build_attr("unicodeBidi", value)
  defp cast_attr({"visibility", value}), do: build_attr("visibility", value)
  defp cast_attr({"word-spacing", value}), do: build_attr("wordSpacing", value)
  defp cast_attr({"writing-mode", value}), do: build_attr("writingMode", value)

  defp cast_attr({_, _}), do: nil

  defp build_attr(elm_func, value) do
    "#{elm_func} \"#{value}\""
  end
end
