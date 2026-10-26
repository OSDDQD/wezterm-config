local gpu_adapters = require('utils.gpu-adapter')

return {
    max_fps = 120,
    animation_fps = 120,
    -- WebGpu смешивает глифы с фоном в линейном пространстве, как Ghostty
    -- (alpha-blending = linear-corrected): на OpenGL тот же шрифт тоньше и рванее.
    -- Известная грабля WebGpu (Vulkan, NVIDIA): у тонких штрихов бывают выпавшие
    -- пиксели («○» в herdr, «3», тусклый текст). Если вылезет — назад на 'OpenGL'
    -- и Medium в appearance.lua.
    front_end = 'WebGpu', ---@type 'WebGpu' | 'OpenGL' | 'Software'
    webgpu_power_preference = 'HighPerformance',
    webgpu_preferred_adapter = gpu_adapters:pick_best(),
}
