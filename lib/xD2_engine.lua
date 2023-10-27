Engine_xD2 = {}

local controlspec = require "controlspec"

local function add_xD2_params(id)
  local suffix = "_" .. id
  local function a(name, key, ctrlspec)
    params:add {
      type = "control",
      id = "xD2_" .. key .. suffix,
      name = name,
      controlspec = ctrlspec,
      action = function(x)
        engine.xDset(key, id, x)
        Engine_xD2.param_changed_callback(key, id, 1, x)
      end,
    }
  end
  local function b(name, key, i, ctrlspec)
    params:add {
      type = "control",
      id = "xD2_" .. key .. "_" .. i .. suffix,
      name = name .. " " .. i,
      controlspec = ctrlspec,
      action = function(x)
        engine.xDindex_set(key, i, id, x)
        Engine_xD2.param_changed_callback(key .. "_" .. i, id, 1, x)
      end,
    }
  end
  local function lin(min, max, default)
    return controlspec.new(min, max, "lin", 0, default)
  end
  local function exp(min, max, default)
    return controlspec.new(min, max, "exp", 0, default)
  end
  local NUM_PARAMS = 72
  params:add_group("xD2_timbre_" .. id, "xD2 Timbre " .. id, NUM_PARAMS)
  a("amp", "amp", lin(0, 1, 0.5))
  params:add {
    type = "control",
    id = "xD2_monophonic" .. suffix,
    name = "monophonic",
    controlspec = controlspec.new(0, 1, "lin", 1, 0),
    action = function(x)
      engine.set_timbre_monophonic(x, id, 0)
      Engine_xD2.param_changed_callback("monophonic", id, 1, x)
    end
  }
  a("lfo freq", "lfreq", exp(0.01, 10, 1))
  a("lfo fade", "lfade", exp(0.01, 10, 0.01))
  a("lfo > amp", "lfo_am", lin(0, 1, 0))
  a("lfo > pitch", "lfo_pm", lin(0, 1, 0))
  params:add_separator("xD2_filters" .. suffix, "filters")
  a("highpass", "hifreq", exp(10, 20000, 50))
  a("res", "hires", lin(0, 1, 0))
  a("lowpass", "lofreq", exp(10, 20000, 10000))
  a("res", "lores", lin(0, 1, 0))
  a("attack", "fatk", lin(0.05, 5, 0.2))
  a("decay", "fdec", lin(0.05, 5, 0.8))
  a("sustain", "fsus", lin(0, 1, 0.3))
  a("release", "frel", lin(0.1, 10, 0.3))
  a("curve", "fcurve", lin(-4, 4, -1))
  a("env > highpass", "hfamt", lin(0, 1, 0))
  a("env > lowpass", "lfamt", lin(0, 1, 1))
  a("lfo > highpass", "lfo_hfm", lin(0, 1, 0))
  a("lfo > lowpass", "lfo_lfm", lin(0, 1, 0))
  params:add_separator("XD2_operators" .. suffix, "operators")
  a("algorithm", "alg", controlspec.new(0, 31, "lin", 1, 0))
  a("feedback", "feedback", lin(0, 1.5, 0))
  a("op env curve", "ocurve", lin(-4, 4, -1))
  for i = 1, 6 do
    params:add_separator("operator_" .. i .. suffix, "operator " .. i)
    b("numerator", "num", i, controlspec.new(1, 30, "lin", 1, 1))
    b("denominator", "denom", i, controlspec.new(1, 30, "lin", 1, 1))
    b("index", "oamp", i, lin(0, 4, 1))
    b("attack", "oatk", i, lin(0.05, 5, 0.2))
    b("decay", "odec", i, lin(0.05, 5, 0.8))
    b("sustain", "osus", i, lin(0, 1, 0.7))
    b("release", "orel", i, lin(0.1, 10, 0.3))
  end
end

local function add_xTurns_params(id)
  local suffix = "_" .. id
  local function a(name, key, ctrlspec)
    params:add {
      type = "control",
      id = "xTurns_" .. key .. suffix,
      name = name,
      controlspec = ctrlspec,
      action = function(x)
        engine.xTset(key, id, x)
        Engine_xD2.param_changed_callback(key, id, 2, x)
      end,
    }
  end
  local function lin(min, max, default)
    return controlspec.new(min, max, "lin", 0, default)
  end
  local function exp(min, max, default)
    return controlspec.new(min, max, "exp", 0, default)
  end
  local NUM_PARAMS = 52
  params:add_group("xTurns_timbre_" .. id, "xTurns Timbre " .. id, NUM_PARAMS)
  a("amp", "amp", lin(0, 1.2, 0.5))
  params:add {
    type = "control",
    id = "xTurns_monophonic" .. suffix,
    name = "monophonic",
    controlspec = controlspec.new(0, 1, "lin", 1, 0),
    action = function(x)
      engine.set_timbre_monophonic(x, id, 1)
      Engine_xD2.param_changed_callback("monophonic", id, 2, x)
    end
  }
  params:add_separator("xTurns_amp_env" .. suffix, "amp env")
  a("attack", "amp_attack", lin(0.05, 5, 0.2))
  a("decay", "amp_decay", lin(0.05, 5, 0.8))
  a("sustain", "amp_sustain", lin(0, 1, 0.7))
  a("release", "amp_release", lin(0.1, 10, 0.3))
  params:add_separator("xTurns_mod_env" .. suffix, "mod env")
  a("attack", "mod_attack", lin(0.05, 5, 0.2))
  a("decay", "mod_decay", lin(0.05, 5, 0.8))
  a("sustain", "mod_sustain", lin(0, 1, 0.7))
  a("release", "mod_release", lin(0.1, 10, 0.3))
  a("env > pitch", "env_pitch_mod", lin(0, 1, 0))
  params:add_separator("xTurns_lfo" .. suffix, "lfo")
  a("lfo freq", "lfo_freq", exp(0.01, 10, 1))
  a("lfo fade", "lfo_fade", lin(0, 10, 0))
  a("lfo > pitch", "lfo_pitch_mod", lin(0, 1, 0))
  a("lfo > amp", "lfo_amp_mod", lin(0, 1, 0))
  params:add_separator("xTurns_square" .. suffix, "square")
  a("amp", "square_amp", lin(0, 1, 0.5))
  params:add{
    type        = "control",
    id          = "xTurns_detune_square_octave" .. suffix,
    name        = "octave",
    controlspec = controlspec.new(-2, 2, "lin", 1, 0),
    action      = function(x)
      local step = params:get("xTurns_detune_square_steps" .. suffix)
      local cent = params:get("xTurns_detune_square_cents" .. suffix) / 100
      x = 12 * x + step + cent
      engine.xTset("detune_square", id, x)
      Engine_xD2.param_changed_callback("detune_square", id, 2, x)
    end,
  }
  params:add{
    type        = "control",
    id          = "xTurns_detune_square_steps" .. suffix,
    name        = "step",
    controlspec = controlspec.new(-12, 12, "lin", 1, 0),
    action      = function(x)
      local octave = params:get("xTurns_detune_square_octave" .. suffix)
      local cent = params:get("xTurns_detune_square_cents" .. suffix) / 100
      x = 12 * octave + x + cent
      engine.xTset("detune_square", id, x)
      Engine_xD2.param_changed_callback("detune_square", id, 2, x)
    end,
  }
  params:add{
    type        = "control",
    id          = "xTurns_detune_square_cents" .. suffix,
    name        = "cents",
    controlspec = controlspec.new(-100, 100, "lin", 0, 0),
    action      = function(x)
      local step = params:get("xTurns_detune_square_steps" .. suffix)
      local octave = params:get("xTurns_detune_square_octave" .. suffix)
      x = 12 * octave + step + x / 100
      engine.xTset("detune_square", id, x)
      Engine_xD2.param_changed_callback("detune_square", id, 2, x)
    end,
  }
  a("width", "width_square", lin(0, 1, 0.5))
  a("env > width", "env_square_width_mod", lin(0, 1, 0))
  a("lfo > width", "lfo_square_width_mod", lin(0, 1, 0))
  a("fm index", "fm_index", lin(0, 1, 0))
  a("env > index", "env_index_mod", lin(0, 1, 0))
  a("lfo > index", "lfo_index_mod", lin(0, 1, 0))
  a("numerator", "fm_numerator", controlspec.new(1, 30, "lin", 1, 1))
  a("denominator", "fm_denominator", controlspec.new(1, 30, "lin", 1, 1))
  params:add_separator("xTurns_formant" .. suffix, "formant")
  a("amp", "formant_amp", lin(0, 1, 0.5))
  a("sq > amp", "square_formant_amp_mod", lin(-1, 1, 0))
  params:add{
    type        = "control",
    id          = "xTurns_detune_formant_octave" .. suffix,
    name        = "octave",
    controlspec = controlspec.new(-2, 2, "lin", 1, 0),
    action      = function(x)
      local step = params:get("xTurns_detune_formant_steps" .. suffix)
      local cent = params:get("xTurns_detune_formant_cents" .. suffix) / 100
      x = 12 * x + step + cent
      engine.xTset("detune_formant", id, x)
      Engine_xD2.param_changed_callback("detune_formant", id, 2, x)
    end,
  }
  params:add{
    type        = "control",
    id          = "xTurns_detune_formant_steps" .. suffix,
    name        = "step",
    controlspec = controlspec.new(-12, 12, "lin", 1, 0),
    action      = function(x)
      local octave = params:get("xTurns_detune_formant_octave" .. suffix)
      local cent = params:get("xTurns_detune_formant_cents" .. suffix) / 100
      x = 12 * octave + x + cent
      engine.xTset("detune_formant", id, x)
      Engine_xD2.param_changed_callback("detune_formant", id, 2, x)
    end,
  }
  params:add{
    type        = "control",
    id          = "xTurns_detune_formant_cents" .. suffix,
    name        = "cents",
    controlspec = controlspec.new(-100, 100, "lin", 0, 0),
    action      = function(x)
      local step = params:get("xTurns_detune_formant_steps" .. suffix)
      local octave = params:get("xTurns_detune_formant_octave" .. suffix)
      x = 12 * octave + step + x / 100
      engine.xTset("detune_formant", id, x)
      Engine_xD2.param_changed_callback("detune_formant", id, 2, x)
    end,
  }
  a("width", "width_formant", lin(0, 1, 0.5))
  a("env > width", "env_formant_width_mod", lin(0, 1, 0))
  a("lfo > width", "lfo_formant_width_mod", lin(0, 1, 0))
  a("formant", "formant", lin(-3, 3, 0))
  a("sq > formant", "square_formant_mod", lin(-1, 1, 0))
  a("env > width", "env_formant_mod", lin(0, 1, 0))
  a("lfo > width", "lfo_formant_mod", lin(0, 1, 0))
  params:add_separator("xTurns_filters" .. suffix, "filters")
  a("highpass", "highpass_freq", exp(10, 20000, 50))
  a("res", "highpass_resonance", lin(0, 1, 0))
  a("env > highpass", "env_highpass_mod", lin(0, 1, 0))
  a("lfo > highpass", "lfo_highpass_mod", lin(0, 1, 0))
  a("lowpass", "lowpass_freq", exp(10, 20000, 10000))
  a("res", "lowpass_resonance", lin(0, 1, 0))
  a("env > lowpass", "env_lowpass_mod", lin(0, 1, 1))
  a("lfo > lowpass", "lfo_lowpass_mod", lin(0, 1, 0))
end

local function add_params(id, type)
  if type == 0 then
    add_xD2_params(id)
  else
    add_xTurns_params(id)
  end
end

local function add_midi_event(mididevices, mididevice_list, midi_channels, dev)
  if not dev.port then return end
  local name = string.lower(dev.name)
  table.insert(mididevice_list, name)
  print("adding " .. name .. " to port " .. dev.port)
  mididevices[name] = {
    name = name,
    port = dev.port,
    midi = midi.connect(dev.port),
    active = false,
  }
  mididevices[name].midi.event = function(data)
    if mididevices[name].active == false then return end
    local d = midi.to_msg(data)
    if d.ch ~= midi_channels[params:get("midichannel")] and params:get("midichannel") > 1 then
      return
    end
    if d.type == "note_on" then
      local amp = util.linexp(1, 127, 0.01, 1.2, d.vel)
      engine.note_on(d.note, amp, 0, 0)
    elseif d.type == "note_off" then
      engine.note_off(d.note, 0, 0)
    elseif d.cc == 64 then
      local val = d.val > 126 and 1 or 0
      if params:get("pedal_mode") == 1 then
        engine.sustain(val)
      else
        engine.sostenuto(val)
      end
    end
  end
end

local function add_midi_params()
  params:add_separator("midi_sep", "midi")
  local mididevices = {}
  local mididevice_list = { "none" }
  local midi_channels = { "all" }
  for i = 1, 16 do
    table.insert(midi_channels, i)
  end
  for _, dev in pairs(midi.devices) do
    add_midi_event(mididevices, mididevice_list, midi_channels, dev)
  end
  tab.print(mididevice_list)
  params:add {
    type    = "option",
    id      = "pedal_mode",
    name    = "pedal mode",
    options = { "sustain", "sostenuto" },
    default = 1,
  }
  params:add {
    type    = "option",
    id      = "midi",
    name    = "midi in",
    options = mididevice_list,
    default = 1,
    action  = function(x)
      if x == 1 then return end
      for _, dev in pairs(mididevices) do
        dev.active = false
      end
      mididevices[mididevice_list[x]].active = true
    end
  }
  params:add {
    type    = "option",
    id      = "midichannel",
    name    = "midi ch",
    options = midi_channels,
    default = 1,
  }
  if #mididevice_list > 1 then
    params:set("midi", 2)
  end
end

function Engine_xD2.init(add_midi, timbrality)
  params:add {
    type        = "control",
    id          = "max_polyphony",
    name        = "max polyphony",
    controlspec = controlspec.new(1, 20, "lin", 1, 20),
    action      = function(x)
      engine.set_polyphony(x)
    end
  }
  if add_midi then
    add_midi_params()
  end
  for i = 0, timbrality - 1 do
    add_params(i, 0)
  end
  for i = 0, timbrality - 1 do
    add_params(i, 1)
  end
end

function Engine_xD2.note_on(note, vel, timbre, Type)
  if not Type then Type = 1 end
  if not timbre then timbre = 0 end
  engine.note_on(note, vel, timbre, Type - 1)
end

function Engine_xD2.note_off(note, timbre, Type)
  if not Type then Type = 1 end
  if not timbre then timbre = 0 end
  engine.note_off(note, timbre, Type - 1)
end

function Engine_xD2.param_changed_callback(...) end

return Engine_xD2
