-- High-level SURFER policy translated from RendererEngine.java and
-- SurfaceExamples.java. Numerical work stays below the engine boundary in C.
--
-- The engine object is deliberately tiny. A future Lua/C binding only needs:
--   set_formula(string)
--   set_camera{ kind, height, z }
--   set_view{ yaw, pitch, zoom }
--   set_background{ r, g, b }
--   set_material(side, table)
--   set_light(index, table)
--   set_antialiasing{ mode, pattern }
--   render{ width, height }
--
-- This keeps Java UI policy out of the numerical core without moving roots,
-- polynomial arithmetic, ray construction, or shading math into Lua.

local surfer = {}

surfer.examples = {
    { name = "Sphere", formula = "x^2+y^2+z^2-0.64" },
    { name = "Torus", formula = "(x^2+y^2+z^2+0.36)^2-1.69*(x^2+y^2)" },
    { name = "Cayley cubic", formula = "x^2+y^2+z^2+2*x*y*z-1" },
    { name = "Whitney umbrella", formula = "x^2-y^2*z" },
    { name = "Roman surface", formula = "x^2*y^2+y^2*z^2+z^2*x^2-x*y*z" },
    { name = "Heart", formula = "(x^2+2.25*y^2+z^2-1)^3-x^2*z^3-0.1125*y^2*z^3" },
}

surfer.defaults = {
    camera = {
        kind = "orthographic",
        height = 2.15,
        z = -1.0,
    },
    background = { r = 0.075, g = 0.09, b = 0.115 },
    front_material = {
        color = { r = 0.90, g = 0.47, b = 0.18 },
        ambient = 0.32,
        diffuse = 0.76,
        specular = 0.55,
        shininess = 24.0,
    },
    back_material = {
        color = { r = 0.93, g = 0.76, b = 0.40 },
        ambient = 0.30,
        diffuse = 0.72,
        specular = 0.45,
        shininess = 18.0,
    },
    lights = {
        { position = { x = -100.0, y = 100.0, z = 100.0 }, color = { r = 1.0, g = 1.0, b = 1.0 }, intensity = 0.55 },
        { position = { x = 100.0, y = 100.0, z = 100.0 }, color = { r = 1.0, g = 1.0, b = 1.0 }, intensity = 0.70 },
        { position = { x = 0.0, y = -100.0, z = 100.0 }, color = { r = 1.0, g = 1.0, b = 1.0 }, intensity = 0.30 },
    },
}

local function copy_table(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy_table(item)
    end
    return result
end

function surfer.new_state()
    return {
        current_formula = false,
        configured = false,
    }
end

function surfer.configure_static(engine)
    engine:set_camera(copy_table(surfer.defaults.camera))
    engine:set_background(copy_table(surfer.defaults.background))
    engine:set_material("front", copy_table(surfer.defaults.front_material))
    engine:set_material("back", copy_table(surfer.defaults.back_material))

    for index, light in ipairs(surfer.defaults.lights) do
        engine:set_light(index - 1, copy_table(light))
    end
    for index = #surfer.defaults.lights, 7 do
        engine:set_light(index, { enabled = false })
    end
end

local function configure_quality(engine, quality)
    local pattern = quality == "interactive" and "OG_1x1" or "QUINCUNX"
    engine:set_antialiasing {
        mode = "adaptive_supersampling",
        pattern = pattern,
    }
end

function surfer.prepare(engine, state, request)
    if not state.configured then
        surfer.configure_static(engine)
        state.configured = true
    end

    if state.current_formula ~= request.formula then
        engine:set_formula(request.formula)
        state.current_formula = request.formula
    end

    engine:set_view {
        yaw = request.yaw,
        pitch = request.pitch,
        zoom = request.zoom,
    }
    configure_quality(engine, request.quality)
end

function surfer.render(engine, state, request)
    surfer.prepare(engine, state, request)
    return engine:render {
        width = request.width,
        height = request.height,
    }
end

return surfer
