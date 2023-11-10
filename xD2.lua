-- xD2
--
-- multi-timbral, multi-architecture polysynth
-- built with love
--
-- @alanza
-- v0.0.1

local xD2 = include("lib/xD2_engine")
UI = require("ui")
Filtergraph = require("filtergraph")
Envgraph = require("envgraph")
Graph = require("graph")
Reflection = include("lib/reflection")
Musicutil = require("musicutil")
local halfsecond = include("lib/halfsecond")
local Voice = 0
local Type = 1
local Tab = {}
Tab.__index = Tab

function Tab.new(params, arc_params, lists, hook)
  local t = {
    params = params,
    arc_params = arc_params,
    lists = lists,
    hook = hook,
    index = 1,
  }
  setmetatable(t, Tab)
  return t
end

function Tab:redraw()
  self:hook()
  for _, list in pairs(self.lists) do
    list:redraw()
  end
end

function Tab:enc(n, d)
  if n == 2 then
    self.index = util.clamp(self.index + d, 1, #self.params)
  elseif n == 3 then
    params:delta(self.params[self.index] .. Voice, d)
  end
end

local Page = {}
Page.__index = Page
function Page.new(titles, tabs)
  local p = {
    tabs = tabs,
    ui = UI.Tabs.new(1, titles)
  }
  setmetatable(p, Page)
  return p
end

function Page:enc(n, d)
  local tab = self.tabs[self.ui.index]
  tab:enc(n, d)
end

function Page:key(n, z)
  if n == 2 and z == 1 then
    self.ui:set_index_delta(-1, true)
  elseif n == 3 and z == 1 then
    self.ui:set_index_delta(1, true)
  end
end

function Page:redraw()
  self.ui:redraw()
  self.tabs[self.ui.index]:redraw()
end

Screen_Dirty = true
Screen = {}

engine.name = "xD2"
norns.version.required = 231010

function init()
  halfsecond.init()
  xD2.init(true, 3)
  Screen = {
    UI.Pages.new(1, 3),
    UI.Pages.new(1, 3),
  }
  local ophook = function(self)
    self.lists[1].index = self.index
    self.lists[1].num_above_selected = 0
    self.lists[2].index = self.index
    for i = 1, 8 do
      self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
    end
    self.lists[2].num_above_selected = 0
    self.lists[2].text_align = "right"
    self.env_graph:edit_adsr(
      params:get(self.params[1] .. Voice),
      params:get(self.params[2] .. Voice),
      params:get(self.params[3] .. Voice),
      params:get(self.params[4] .. Voice),
      params:get(self.params[7] .. Voice) / 4,
      params:get("xD2_ocurve_" .. Voice)
    )
    self.env_graph:redraw()
  end
  local titles, tabs = {}, {}
  for i = 1, 6 do
    titles[i] = tostring(i)
    tabs[i] = Tab.new({
      "xD2_oatk_" .. i .. "_",
      "xD2_odec_" .. i .. "_",
      "xD2_osus_" .. i .. "_",
      "xD2_orel_" .. i .. "_",
      "xD2_num_" .. i .. "_",
      "xD2_denom_" .. i .. "_",
      "xD2_oamp_" .. i .. "_",
      "xD2_ocurve_",
    }, {
      { 1, 2, 3, 4 },
      { 5, 6, 7, 8 },
    }, {
      UI.ScrollingList.new(70, 24, 1, {
        "atk", "dec", "sus", "rel", "num", "denom", "index", "curve",
      }),
      UI.ScrollingList.new(120, 24)
    }, ophook)
    local adsr_params = {
      params:get("xD2_oatk_1_0"),
      params:get("xD2_odec_1_0"),
      params:get("xD2_osus_1_0"),
      params:get("xD2_orel_1_0"),
    }
    local env_graph = Envgraph.new_adsr(
      0, 20, nil, nil, table.unpack(adsr_params), 1, -4
    )
    env_graph:set_position_and_size(4, 22, 56, 38)
    tabs[i].env_graph = env_graph
  end
  Screen[1][1] = Page.new(titles, tabs)
  Screen[1][2] = Page.new({ "FILTER", "LFO" },
    {
      Tab.new({
          "xD2_fatk_", "xD2_fdec_", "xD2_fsus_", "xD2_frel_",
          "xD2_hifreq_", "xD2_hires_", "xD2_lofreq_", "xD2_lores_",
          "xD2_hfamt_", "xD2_lfamt_", "xD2_fcurve_",
        },
        {
          { 7, 8, 5, 6, },
          { 1, 2, 3, 4, },
        },
        {
          UI.ScrollingList.new(70, 24, 1, {
            "atk", "dec", "sus", "rel", "high", "res", "low", "res", "e>hi", "e>low", "curve"
          }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 0
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 0
          for i = 1, 11 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.env_graph:edit_adsr(
            params:get(self.params[1] .. Voice),
            params:get(self.params[2] .. Voice),
            params:get(self.params[3] .. Voice),
            params:get(self.params[4] .. Voice),
            nil,
            params:get("xD2_fcurve_" .. Voice)
          )
          self.env_graph:redraw()
        end),
      Tab.new({
          "xD2_lfreq_", "xD2_lfade_", "xD2_lfo_am_", "xD2_lfo_pm_",
          "xD2_lfo_hfm_", "xD2_lfo_lfm_",
        }, {
          { 1, 2, 3, 4 },
          { 1, 2, 5, 6 },
        },
        {
          UI.ScrollingList.new(70, 24, 1, { "freq", "fade", "l>amp", "l>pit", "l>hi", "l>low" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 0
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 0
          for i = 1, 6 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.lfo_graph:update_functions()
          self.lfo_graph:redraw()
        end)
    })
  local adsr_params = { params:get("xD2_fatk_0"), params:get("xD2_fdec_0"), params:get("xD2_fsus_0"),
    params:get("xD2_frel_0") }
  Screen[1][2].tabs[1].env_graph = Envgraph.new_adsr(0, 20, nil, nil, table.unpack(adsr_params), 1, -4)
  Screen[1][2].tabs[1].env_graph:set_position_and_size(4, 22, 56, 38)
  Screen[1][2].tabs[2].lfo_graph = Graph.new(0, 1, "lin", -1, 1, "lin", nil, true, false)
  Screen[1][2].tabs[2].lfo_graph:set_position_and_size(4, 22, 56, 38)
  Screen[1][2].tabs[2].lfo_graph:add_function(function(x)
    local id = Voice
    local freq = params:get("xD2_lfreq_" .. id)
    local fade = params:get("xD2_lfade_" .. id)
    local fade_end
    local y_fade
    local MIN_Y = 0.15

    fade_end = util.linlin(0, 10, 0, 1, fade)
    y_fade = util.linlin(0, fade_end, MIN_Y, 1, x)
    x = x * util.linlin(0.01, 10, 0.5, 10, freq)
    local y = math.sin(x * math.pi * 2)
    return y * y_fade * 0.75
  end, 4)
  Screen[1][3] = Page.new({ "MISC" },
    {
      Tab.new({ "xD2_alg_", "xD2_monophonic_", "xD2_feedback_" },
        {
          { 1, 2, 3, 3 },
          { 1, 2, 3, 3 },
        },
        {
          UI.List.new(70, 34, 1, { "alg", "mono", "fdbk" }),
          UI.List.new(120, 34)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[2].index = self.index
          for i = 1, 3 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          screen.level(10)
          local alg_path = _path.code .. "xD2/img/" .. params:get("xD2_alg_" .. Voice) .. ".png"
          screen.display_png(alg_path, 4, 24)
          screen.fill()
        end),
    })
  Screen[2][1] = Page.new({ "SQUARE", "FORMANT" },
    {
      Tab.new(
        { "xTurns_square_amp_", "xTurns_width_square_", "xTurns_lfo_square_width_mod_", "xTurns_env_square_width_mod_",
          "xTurns_fm_numerator_", "xTurns_fm_denominator_", "xTurns_fm_index_", "xTurns_lfo_index_mod_",
          "xTurns_env_index_mod_", "xTurns_detune_square_octave_", "xTurns_detune_square_steps_",
          "xTurns_detune_square_cents_", "xTurns_lfo_pitch_mod_", "xTurns_env_pitch_mod_" },
        {
          { 1, 2, 3, 14 },
          { 5, 6, 7, 9 },
        },
        {
          UI.ScrollingList.new(70, 24, 1,
            { "amp", "width", "l>width", "e>width", "num", "denom", "index", "l>index", "e>index", "oct", "coarse",
              "fine", "l>pitch", "e>pitch" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 1
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 1
          for i = 1, 14 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.osc_graph:update_functions()
          self.osc_graph:redraw()
        end),
      Tab.new(
        { "xTurns_width_formant_", "xTurns_lfo_formant_width_mod_", "xTurns_env_formant_width_mod_", "xTurns_formant_",
          "xTurns_square_formant_mod_", "xTurns_lfo_formant_mod_", "xTurns_env_formant_mod_",
          "xTurns_detune_formant_octave_", "xTurns_detune_formant_steps_", "xTurns_detune_formant_cents_",
          "xTurns_lfo_pitch_mod_", "xTurns_env_pitch_mod_", "xTurns_formant_amp_", "xTurns_square_formant_amp_mod_",
          "xTurns_lfo_amp_mod_" },
        {
          { 1, 4, 13, 12 },
          { 2, 5, 6,  14 },
        },
        {
          UI.ScrollingList.new(70, 24, 1,
            { "width", "l>width", "e>width", "formant", "sq>form", "l>form", "e>form", "oct", "coarse", "fine",
              "l>pitch", "e>pitch", "amp", "sq>amp", "l>amp" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 1
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 1
          for i = 1, 15 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.osc_graph:update_functions()
          self.osc_graph:redraw()
        end)
    })
  local function sq_func(x)
    local w = params:get("xTurns_width_square_" .. Voice)
    local ratio = params:get("xTurns_fm_numerator_" .. Voice) / params:get("xTurns_fm_denominator_" .. Voice)
    local index = params:get("xTurns_fm_index_" .. Voice)
    x = x + math.sin(x * math.pi * 2 * ratio) * index
    local y = x % 1 < w and -1 or 1
    return y
  end
  local offset = -1
  local last = 0
  local state = false
  local function form_func(x)
    x = x * 4
    local w = params:get("xTurns_width_formant_" .. Voice)
    local sq = sq_func(x)
    local form = 2 ^ params:get("xTurns_formant_" .. Voice)
    form = form + sq * params:get("xTurns_square_formant_mod_" .. Voice)
    if form == 0 then
      form = 0.0001
    end
    if form < 0 then
      form = -form
    end
    local v = (1 - w) / form
    w = w / form
    local a = 2 / w
    local b = -2 / v
    local y
    if not state then
      -- rise: do we start falling?
      if a * (x - last) + offset > 1 then
        state = not state
        last = x
      end
    else
      -- fall: do we start rising?
      if x % 1 < 0.01 then
        state = not state
        offset = math.max(b * (x - last) + 1, -1)
        last = x
      end
    end
    if state then
      -- falling
      y = math.max(b * (x - last) + 1, -1)
    else
      y = a * (x - last) + offset
    end
    local am = sq * params:get("xTurns_square_formant_amp_mod_" .. Voice)
    if x == 4 then
      state = false
      last = 0
      offset = -1
    end
    return util.clamp(y * (params:get("xTurns_formant_amp_" .. Voice) + am), -1, 1)
  end
  for i = 1, 2 do
    Screen[2][1].tabs[i].osc_graph = Graph.new(0, 1, "lin", -1, 1, "lin", nil, true, false)
    Screen[2][1].tabs[i].osc_graph:set_position_and_size(4, 22, 56, 38)
  end
  Screen[2][1].tabs[1].osc_graph:add_function(function(x)
    local y = sq_func(x)
    return y * params:get("xTurns_square_amp_" .. Voice)
  end, 4)
  Screen[2][1].tabs[2].osc_graph:add_function(form_func, 4)
  Screen[2][2] = Page.new({ "AMP ENV", "MOD ENV", "LFO" },
    {
      Tab.new({ "xTurns_amp_attack_", "xTurns_amp_decay_", "xTurns_amp_sustain_", "xTurns_amp_release_" },
        {
          { 1, 2, 3, 4 },
          { 1, 2, 3, 4 },
        },
        {
          UI.ScrollingList.new(70, 24, 1, { "atk", "dec", "sus", "rel" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 1
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 1
          for i = 1, 4 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.env_graph:edit_adsr(params:get(self.params[1] .. Voice), params:get(self.params[2] .. Voice),
            params:get(self.params[3] .. Voice), params:get(self.params[4] .. Voice))
          self.env_graph:redraw()
        end),
      Tab.new({ "xTurns_mod_attack_", "xTurns_mod_decay_", "xTurns_mod_sustain_", "xTurns_mod_release_" },
        {
          { 1, 2, 3, 4 },
          { 1, 2, 3, 4 },
        },
        {
          UI.ScrollingList.new(70, 24, 1, { "atk", "dec", "sus", "rel" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 1
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 1
          for i = 1, 4 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.env_graph:edit_adsr(params:get(self.params[1] .. Voice), params:get(self.params[2] .. Voice),
            params:get(self.params[3] .. Voice), params:get(self.params[4] .. Voice))
          self.env_graph:redraw()
        end),
      Tab.new({ "xTurns_lfo_freq_", "xTurns_lfo_fade_" },
        {
          { 1, 2, 1, 2 },
          { 1, 2, 1, 2 },
        },
        {
          UI.List.new(70, 24, 1, { "freq", "fade" }),
          UI.List.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[2].index = self.index
          for i = 1, 2 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.lfo_graph:update_functions()
          self.lfo_graph:redraw()
        end)
    })
  Screen[2][2].tabs[1].env_graph = Envgraph.new_adsr(0, 20, nil, nil, nil, nil, nil, nil, 1, -4)
  Screen[2][2].tabs[2].env_graph = Envgraph.new_adsr(0, 20, nil, nil, nil, nil, nil, nil, 1, -4)
  Screen[2][2].tabs[3].lfo_graph = Graph.new(0, 1, "lin", -1, 1, "lin", nil, true, false)
  Screen[2][2].tabs[1].env_graph:set_position_and_size(4, 22, 56, 38)
  Screen[2][2].tabs[2].env_graph:set_position_and_size(4, 22, 56, 38)
  Screen[2][2].tabs[3].lfo_graph:set_position_and_size(4, 22, 56, 38)
  Screen[2][2].tabs[3].lfo_graph:add_function(function(x)
    local freq = params:get("xTurns_lfo_freq_" .. Voice)
    local fade = params:get("xTurns_lfo_fade_" .. Voice)
    local fade_end
    local y_fade
    local MIN_Y = 0.15

    fade_end = util.linlin(0, 10, 0, 1, fade)
    y_fade = util.linlin(0, fade_end, MIN_Y, 1, x)
    x = x * util.linlin(0.01, 10, 0.5, 10, freq)
    local y = math.sin(x * math.pi * 2)
    return y * y_fade * 0.75
  end, 4)
  Screen[2][3] = Page.new({ "HIPASS", "LOPASS" },
    {
      Tab.new(
        { "xTurns_highpass_freq_", "xTurns_highpass_resonance_", "xTurns_lfo_highpass_mod_", "xTurns_env_highpass_mod_" },
        {
          { 1, 2, 3, 4 },
          { 1, 2, 3, 4 },
        },
        {
          UI.ScrollingList.new(70, 24, 1, { "freq", "res", "l>freq", "e>freq" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 1
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 1
          for i = 1, 4 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.filt_graph:edit("highpass", nil, params:get(self.params[1] .. Voice), params:get(self.params[2] .. Voice))
          self.filt_graph:redraw()
        end),
      Tab.new(
        { "xTurns_lowpass_freq_", "xTurns_lowpass_resonance_", "xTurns_lfo_lowpass_mod_", "xTurns_env_lowpass_mod_" },
        {
          { 1, 2, 3, 4 },
          { 1, 2, 3, 4 },
        },
        {
          UI.ScrollingList.new(70, 24, 1, { "freq", "res", "l>freq", "e>freq" }),
          UI.ScrollingList.new(120, 24)
        },
        function(self)
          self.lists[1].index = self.index
          self.lists[1].num_above_selected = 1
          self.lists[2].index = self.index
          self.lists[2].num_above_selected = 1
          for i = 1, 4 do
            self.lists[2].entries[i] = params:string(self.params[i] .. Voice)
          end
          self.lists[2].text_align = "right"
          self.filt_graph:edit("lowpass", nil, params:get(self.params[1] .. Voice), params:get(self.params[2] .. Voice))
          self.filt_graph:redraw()
        end)
    })
  Screen[2][3].tabs[1].filt_graph = Filtergraph.new(10, 20000, -60, 32.5, "highpass", 12,
    params:get("xTurns_highpass_freq_" .. Voice), params:get("xTurns_highpass_resonance_" .. Voice))
  Screen[2][3].tabs[2].filt_graph = Filtergraph.new(10, 20000, -60, 32.5, "lowpass", 12,
    params:get("xTurns_lowpass_freq_" .. Voice), params:get("xTurns_lowpass_resonance_" .. Voice))
  Screen[2][3].tabs[1].filt_graph:set_position_and_size(4, 22, 56, 38)
  Screen[2][3].tabs[2].filt_graph:set_position_and_size(4, 22, 56, 38)

  params:bang()
  Arc_Data = {}
  for i = 1, 2 do
    for _, page in ipairs(Screen[i]) do
      for _, tab in ipairs(page.tabs) do
        for m = 1, 2 do
          for n = 1, 4 do
            for v = 0, 2 do
              local num = tab.arc_params[m][n]
              local id = tab.params[num] .. v
              Arc_Data[id] = params:get(id)
                Arc_Data[id].range = params:lookup_param(id):get_range()
            end
          end
        end
      end
    end
  end
  Arc_Dirty = true
  local arc_process_metro = metro.init()
  arc_process_metro.event = function()
    if Arc_Dirty then
      arc_redraw()
    end
  end
  if arc_process_metro then
    arc_process_metro:start(1 / 15)
  end

  Grid_Dirty = true

  Narcissus = {}
  Lilies = {}
  for i = 1, 3 do
    Narcissus[i] = Reflection.new()
    Narcissus[i].subloop = nil
    Narcissus[i].jump = nil
    Narcissus[i].process = grid_note
    Narcissus[i].step_callback = function()
      Grid_Dirty = true
      if Narcissus[i].endpoint == 0 then return end
      if Narcissus[i].jump then
        local remainder = Narcissus[i].step % 96
        Narcissus[i].step = Narcissus[i].jump + remainder
        Narcissus[i].jump = nil
      elseif Narcissus[i].subloop then
        if Narcissus[i].step >= Narcissus[i].subloop[2] then
          local remainder = Narcissus[i].step % 96
          Narcissus[i].step = Narcissus[i].subloop[1] + remainder
        end
      end
    end
    Lilies[i] = Reflection.new()
    Lilies[i].subloop = nil
    Lilies[i].jump = nil
    Lilies[i].lights = {}
    Narcissus[i].lights = {}
    for x = 1, 16 do
      Narcissus[i].lights[x] = 0
      Lilies[i].lights[x] = 0
    end
    Lilies[i].process = process_param_event
    Lilies[i].step_callback = function()
      Grid_Dirty = true
      if Lilies[i].endpoint == 0 then return end
      if Lilies[i].jump then
        local remainder = Lilies[i].step % 96
        Lilies[i].step = Lilies[i].jump + remainder
        Lilies[i].jump = nil
      elseif Lilies[i].subloop then
        if Lilies[i].step >= Lilies[i].subloop[2] then
          local remainder = Lilies[i].step % 96
          Lilies[i].step = Lilies[i].subloop[1] + remainder
        end
      end
    end
    Narcissus[i].end_of_rec_callback = function()
      calculate_lights(Narcissus[i])
    end
    Lilies[i].end_of_rec_callback = function()
      calculate_lights(Lilies[i])
    end
  end
  local screen_redraw_metro = metro.init()
  screen_redraw_metro.event = function()
    if not Screen_Dirty then return end
    redraw()
  end
  if screen_redraw_metro then
    screen_redraw_metro:start(1 / 15)
  end
  local grid_redraw_metro = metro.init()
  grid_redraw_metro.event = function()
    if not Grid_Dirty then return end
    one_redraw()
    two_redraw()
  end
  if grid_redraw_metro then
    grid_redraw_metro:start(1 / 30)
  end
  screen.aa(1)
end

local function draw_title()
  screen.level(15)
  screen.move(4, 15)
  local text = Type == 1 and "xD" or "xT"
  screen.text(text .. Voice)
  screen.fill()
end

function redraw()
  Screen_Dirty = false
  screen.clear()
  draw_title()
  Screen[Type]:redraw()
  Screen[Type][Screen[Type].index]:redraw()
  screen.update()
end

function enc(n, d)
  if n == 1 then
    if Alt_Pressed then
      Voice = util.clamp(Voice + d, 0, 4)
    else
      Screen[Type]:set_index_delta(d, false)
      Screen_Dirty = true
      return
    end
  end
  Screen[Type][Screen[Type].index]:enc(n, d)
  Screen_Dirty = true
end

Alt_Pressed = false

function key(n, z)
  if n == 1 then
    Alt_Pressed = z == 1
  end
  if Alt_Pressed and n ~= 1 then
    if z == 1 then Type = 3 - Type end
  end
  Screen[Type][Screen[Type].index]:key(n, z)
  Screen_Dirty = true
end

One_Presses = {}
Two_Presses = {}

for x = 1, 16 do
  One_Presses[x] = {}
  Two_Presses[x] = {}
  for y = -2, 11 do
    One_Presses[x][y] = 0
    Two_Presses[x][y] = 0
  end
end

One = grid.connect(1)
Two = grid.connect(2)

String = 0

local function fret_to_note(x, y)
  return 40 + x + ((8 - y) * 5)
end

function one_redraw()
  Grid_Dirty = false
  One:all(0)
  One:led(1, 1, One_Presses[1][1] == 1 and 15 or 8)
  One:led(1, 2, One_Presses[1][2] == 1 and 15 or 8)
  One:led(1, 4, One_Presses[1][4] == 1 and 15 or 8)
  One:led(1, 5, One_Presses[1][5] == 1 and 15 or 8)
  One:led(1, 7, One_Presses[1][7] == 1 and 15 or 8)
  One:led(1, 8, One_Presses[1][8] == 1 and 15 or 8)
  for x = 2, 16 do
    for y = 1, 8 do
      local light = One_Presses[x][y - String]
      if light == 1 then
        One:led(x, y, 15)
      elseif light == 2 then
        One:led(x, y, 10)
      else
        local note = fret_to_note(x, y - String)
        if string.find(Musicutil.note_num_to_name(note), "#") then
          One:led(x, y, 4)
        end
      end
    end
  end
  One:refresh()
end

function grid_note(event)
  local note = fret_to_note(event.x, event.y)
  if event.t == Type and event.v == Voice then
    One_Presses[event.x][event.y] = event.z
  else
    One_Presses[event.x][event.y] = event.z == 1 and 2 or 0
  end
  if event.z == 1 then
    xD2.note_on(note, 0.8, event.v, event.t)
  else
    xD2.note_off(note, event.v, event.t)
  end
  Grid_Dirty = true
end

One.key = function(x, y, z)
  Grid_Dirty = true
  if x == 1 then
    One_Presses[x][y] = z
    if y == 1 and z == 1 then
      Type = 1
      Screen_Dirty = true
    elseif y == 2 and z == 1 then
      Type = 2
      Screen_Dirty = true
    elseif y == 4 and z == 1 then
      Voice = util.clamp(Voice - 1, 0, 2)
      Screen_Dirty = true
    elseif y == 5 and z == 1 then
      Voice = util.clamp(Voice + 1, 0, 2)
      Screen_Dirty = true
    elseif y == 7 and z == 1 then
      String = util.clamp(String - 1, -3, 3)
    elseif y == 8 and z == 1 then
      String = util.clamp(String + 1, -3, 3)
    end
  else
    local event = {
      x = x,
      y = y - String,
      z = z,
      v = Voice,
      t = Type,
    }
    for i = 1, 3 do
      Narcissus[i]:watch(event)
    end
    grid_note(event)
  end
end

function process_param_event(event)
  Arc_Dirty = true
  Screen_Dirty = true
  local found, s_end = string.find(event.key, "_%d$")
    if found and s_end then
        engine.xDindex_set(string.sub(event.key, 1, found), tonumber(string.sub(event.key, s_end, s_end)), event.v,
            event.x)
        params:set("xD_2" .. event.key .. "_" .. event.v, event.x, true)
    elseif event.key == "monophonic" then
        engine.set_timbre_monophonic(event.x, event.v, event.t)
        if event.t == 1 then
            params:set("xD2_monophonic_" .. event.v, event.x, true)
        else
            params:set("xTurns_monophonic_" .. event.v, event.x, true)
        end
    elseif event.key == "detune_square" then
        engine.xTset("detune_square", event.v, event.x)
        local cents = event.x % 1
        local steps = (event.x - cents) % 12
        local octave = event.x - cents - steps
        params:set("xTurns_detune_square_cents_" .. event.v, cents, true)
        params:set("xTurns_detune_square_steps_" .. event.v, steps, true)
        params:set("xTurns_detune_square_octave_" .. event.v, octave, true)
    elseif event.key == "detune_formant" then
        engine.xTset("detune_formant", event.v, event.x)
        local cents = event.x % 1
        local steps = (event.x - cents) % 12
        local octave = event.x - cents - steps
        params:set("xTurns_detune_formant_cents_" .. event.v, cents, true)
        params:set("xTurns_detune_formant_steps_" .. event.v, steps, true)
        params:set("xTurns_detune_formant_octave_" .. event.v, octave, true)
        Screen_Dirty = true
        return
    else
        if event.t == 1 then
            engine.xDset(event.key, event.v, event.x)
            params:set("xD2_" .. event.key .. "_" .. event.v, event.x, true)
        else
            engine.xTset(event.key, event.v, event.x)
            params:set("xTurns_" .. event.key .. "_" .. event.v, event.x, true)
        end
    end
  local id
    if event.t == 1 then
        id = "xD2_" .. event.key .. "_" .. event.v
    else
        id = "xTurns_" .. event.key .. "_" .. event.v
    end
    if Arc_Data[id] then Arc_Data[id] = event.x end
end

function xD2.param_changed_callback(key, v, t, x)
  local event = {
    key = key,
    v = v,
    t = t,
    x = x,
  }
  for i = 1, 3 do
    Lilies[i]:watch(event)
  end
  Arc_Dirty = true
  local id
  if t == 1 then
    id = "xD2_" .. key .. "_" .. v
  else
    id = "xTurns_" .. key .. "_" .. v
  end
  if Arc_Data[id] then
    Arc_Data[id] = x
  end
end

Arc = arc.connect()

function Arc.delta(n, d)
  d = d * 0.2
  local page = Screen[Type][Screen[Type].index]
  local tab = page.tabs[page.ui.index]
  local num = tab.arc_params[Alt_Pressed and 2 or 1][n]
  local id = tab.params[num] .. Voice
  params:delta(id, d)
  Arc_Dirty = true
end

local ARCMIN = -0.8 * math.pi
local ARCMAX = 0.8 * math.pi

function arc_redraw()
  Arc_Dirty = false
  local page = Screen[Type][Screen[Type].index]
  local tab = page.tabs[page.ui.index]
  Arc:all(0)
  for i = 1, 4 do
    local num = tab.arc_params[Alt_Pressed and 2 or 1][i]
    local id = tab.params[num] .. Voice
    local min = Arc_Data[id].range[1] 
    local max = Arc_Data[id].range[2]
    local center = util.linlin(min, max, ARCMIN,  ARCMAX, Arc_Data[id])
    Arc:segment(i, center - 0.1, center + 0.1, 15)
  end
  Arc:refresh()
end

SPEED = 5

function two_redraw()
  Two:all(0)
  for i = 1, 3 do
    local x = 2 * i + 4
    local n_state = Narcissus[i].play == 1 and 9 or 4
    local l_state = Lilies[i].play == 1 and 9 or 4
    Two:led(x, 1, Two_Presses[x][1] == 1 and 15 or n_state)
    Two:led(x + 1, 1, Two_Presses[x + 1][1] == 1 and 15 or l_state)
    n_state = Narcissus[i].rec_enabled == 1 and 12 or 2
    l_state = Lilies[i].rec_enabled == 1 and 12 or 2
    Two:led(x, 2, Two_Presses[x][2] == 1 and 15 or n_state)
    Two:led(x + 1, 2, Two_Presses[x + 1][2] == 1 and 15 or l_state)
  end
  for i = 1, 3 do
    local y = 2 * i + 1
    for x = 1, 16 do
      local offset = (x - 1) * 96
      if Two_Presses[x][y] == 1 then
        Two:led(x, y, 15)
      elseif Narcissus[i].play == 1 and Narcissus[i].step >= offset and Narcissus[i].step <= offset + 95 then
        Two:led(x, y, 13)
      else
        local light = Narcissus[i].lights[x] > 1 and 5 or (Narcissus[i].lights[x] == 1 and 3 or 0)
        if Narcissus[i].subloop and Narcissus[i].subloop[1] <= offset and Narcissus[i].subloop[2] >= offset then
          light = light + 3
        end
        Two:led(x, y, light)
      end
      if Two_Presses[x][y + 1] == 1 then
        Two:led(x, y + 1, 15)
      elseif Lilies[i].play == 1 and Lilies[i].step >= offset and Lilies[i].step <= offset + 95 then
        Two:led(x, y + 1, 13)
      else
        local light = Lilies[i].lights[x] > 1 and 5 or (Lilies[i].lights[x] == 1 and 3 or 0)
        if Lilies[i].subloop and Lilies[i].subloop[1] <= offset and Lilies[i].subloop[2] >= offset then
          light = light + 3
        end
        Two:led(x, y + 1, light)
      end
    end
  end
  Two:refresh()
end

Two.key = function(x, y, z)
  Grid_Dirty = true
  Two_Presses[x][y] = z
  -- play toggles
  if y == 1 then
    if z == 0 then return end
    if 6 <= x and x <= 11 then
      local i = (x - 4) // 2
      local self
      if x % 2 == 0 then self = Narcissus[i] else self = Lilies[i] end
      if self.play == 0 then
        self:set_loop(1)
        if self.endpoint > 0 then
          self:start(1)
        else
          self:set_rec(1, 16, 1)
        end
      else
        self:set_loop(0)
      end
    end
    -- rec toggles
  elseif y == 2 then
    if z == 0 then return end
    if 6 <= x and x <= 11 then
      local i = (x - 4) // 2
      local self
      if x % 2 == 0 then self = Narcissus[i] else self = Lilies[i] end
      if self.rec_enabled > 0 then
        if self.endpoint > 0 then
          self:set_rec(0)
        end
      else
        if self.endpoint > 0 then
          self:set_loop(1)
          self:set_rec(1, nil, 1)
        else
          self:set_loop(1)
          self:set_rec(1, 16, 1)
        end
      end
    end
    -- jump or set subloop
  else
    if z == 1 then return end
    local i = (y - 1) // 2
    local self
    if y % 2 == 1 then self = Narcissus[i] else self = Lilies[i] end
    for u = 1, 16 do
      if Two_Presses[u][y] == 1 then
        if u <= x then
          self.subloop = { (u - 1) * 96, (x - 1) * 96 }
        else
          self.subloop = { (x - 1) * 96, (u - 1) * 96 }
        end
        return
      end
    end
    self.jump = (x - 1) * 96
  end
end

function calculate_lights(self)
  for i = 1, 16 do
    local total = 0
    local offset = (i - 1) * 96
    for n = 0, 95 do
      if self.event[offset + n] then
        total = total + #self.event[offset + n]
      end
    end
    self.lights[i] = total
  end
end
