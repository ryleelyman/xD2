// polytimbral polysynth engine
// polyphony code inspired by MxSynths by infinitedigits @schollz

// this is a CroneEngine
Engine_xD2 : CroneEngine {
	var endOfChain,
	outBus,
	xDParameters,
	xTParameters,
	xVoices,
	xVoicesOn,
	xDTimbres,
	xTTimbres,
	fnNoteOn, fnNoteOnMono, fnNoteOnPoly, fnNoteAdd,
	fnNoteOff, fnNoteOffMono, fnNoteOffPoly,
	pedalSustainOn=false,
	pedalSostenutoOn=false,
	pedalSustainNotes, pedalSostenutoNotes,
	timbralityMax=16, polyphonyMax=20, polyphonyCount=0;

	*new {
		arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		outBus = Bus.audio;
		SynthDef("ColorLimiter", { arg input;
			Out.ar(context.out_b, In.ar(input).tanh.dup);
		}).add;

		Server.default.sync;
		endOfChain = Synth.new("ColorLimiter", [\input, outBus]);
		NodeWatcher.register(endOfChain);

		xDParameters = (
			amp: 0.5,
			monophonic: 0,
			alg: 0,

			num: (1 ! 6),
			denom: (1 ! 6),

			oatk: (0.2 ! 6),
			odec: (0.8 ! 6),
			osus: (0.5 ! 6),
			orel: (0.3 ! 6),
			oamp: (1 ! 6),
			ocurve: -1,

			fatk: 0.2,
			fdec: 0.8,
			fsus: 0.3,
			frel: 0.3,
			fcurve: -1,

			lfreq: 1,
			lfade: 0,
			lfo_am: 0,
			lfo_pm: 0,
			lfo_hfm: 0,
			lfo_flm: 0,

			note: 69,

			hifreq: 50,
			hfamt: 0,
			hires: 0,
			lofreq: 10000,
			lfamt: 1,
			lores: 0,

			feedback: 0,
		);

		32.do({ arg i; SynthDef(("xD2_"++i).asString, {
			var gate = \gate.kr(1);
			var num = \num.kr(1 ! 6);
			var denom = \denom.kr(1 ! 6);
			var oatk = \oatk.kr(0.2 ! 6);
			var odec = \odec.kr(0.8 ! 6);
			var osus = \osus.kr(0.5 ! 6);
			var orel = \orel.kr(0.3 ! 6);
			var maxrel = ArrayMax.kr(orel)[0];
			var menv = Env.asr(0, 1, maxrel).kr(2, gate);
			var fenv = Env.adsr(
				\fatk.kr(0.2),
				\fdec.kr(0.8),
				\fsus.kr(0.3),
				\frel.kr(0.3), 1,
				\fcurve.kr(-1)
			).kr(0, gate);
			var oenv = Env.adsr(oatk, odec, osus, orel, 1, \ocurve.kr(-1)).kr(0, gate);
			var oamp = \oamp.kr(1 ! 6);
			var ratios = Array.fill(6, {arg i; num[i] / denom[i]; });
			var lfo = LFTri.kr(\lfreq.kr(1), mul:Env.asr(\lfade.kr(0), 1, 10).kr(0, gate));
			var alfo = lfo.madd(0.05, 1.0) * \lfo_am.kr(0);
			var note = \note.kr(69);
			var pitch = (note + (1.2 * \lfo_pm.kr(0) * lfo)).midicps;
			var ctls = Array.fill(6, { arg i;
				[pitch * ratios[i], 0, (oenv[i] + alfo) * oamp[i]];
			});
			var hifreq = (\hifreq.kr(50).cpsmidi
				+ (1.2 * \lfo_hfm.kr(0) * lfo)
				+ (1.2 * fenv * \hfamt.kr(0))).midicps;
			var lofreq = (\lofreq.kr(10000).cpsmidi
				+ (1.2 * \lfo_lfm.kr(0) * lfo)
				+ (1.2 * fenv * \lfamt.kr(1))).midicps;
			var snd = Mix.ar(FM7.arAlgo(i, ctls, \feedback.kr(0)));
			snd = SVF.ar(snd, hifreq, \hires.kr(0), lowpass:0, highpass:1);
			snd = SVF.ar(snd, lofreq, \lores.kr(0));
			Out.ar(\out.ir, (snd * \amp.kr(0.5) * menv * 0.5));
		}).add; });

		xTParameters = (
			amp: 0.5,
			monophonic: 0,

			amp_attack: 0.2,
			amp_decay: 0.8,
			amp_sustain: 0.5,
			amp_release: 0.3,

			mod_attack: 0.2,
			mod_decay: 0.8,
			mod_sustain: 0.5,
			mod_release: 0.3,

			lfo_freq: 1,
			lfo_fade: 0,
			lfo_amp_mod: 0,
			lfo_pitch_mod: 0,
			lfo_square_width_mod: 0,
			lfo_index_mod: 0,
			lfo_formant_width_mod: 0,
			lfo_formant_mod: 0,
			lfo_highpass_mod: 0,
			lfo_lowpass_mod: 0,

			env_pitch_mod: 0,
			env_square_width_mod: 0,
			env_index_mod: 0,
			env_formant_width_mod: 0,
			env_formant_mod: 0,
			env_highpass_mod: 0,
			env_lowpass_mod: 1,

			note: 69,
			
			detune_square: 0,
			width_square: 0.5,
			fm_index: 0,
			fm_numerator: 1,
			fm_denominator: 1,
			square_amp: 0.5,

			detune_formant: 0,
			width_formant: 0.5,
			formant: 0,
			square_formant_mod: 0,
			formant_amp: 0.5,
			square_formant_amp_mod: 0,

			highpass_freq: 50,
			highpass_resonance: 0,
			lowpass_freq: 10000,
			lowpass_resonance: 0,
		);

		SynthDef("xTurns", {
			var gate = \gate.kr(1);
			var env = Env.adsr(
				\amp_attack.kr(0.2),
				\amp_decay.kr(0.8),
				\amp_sustain.kr(0.5),
				\amp_release.kr(0.3),
			).kr(2, gate);
			var modenv = Env.adsr(
				\mod_attack.kr(0.2),
				\mod_decay.kr(0.8),
				\mod_sustain.kr(0.5),
				\mod_release.kr(0.3),
			).kr(0, gate);
			var lfo = LFTri.kr(
				\lfo_freq.kr(1),
				mul:Env.asr(\lfo_fade.kr(0), 1, 10).kr(0, gate)
			);
			var amp_lfo = lfo.madd(0.05, 0.05) * \lfo_amp_mod.kr(0);
			var note = \note.kr(69);
			var pitch_mod = (1.2 * \lfo_pitch_mod.kr(0) * lfo)
			+ (1.2 * modenv * \env_pitch_mod.kr(0));
			var pitch_sq = (note + \detune_square.kr(0) + pitch_mod).midicps;
			var width_sq = \width_square.kr(0.5)
			+ (0.5 * \lfo_square_width_mod.kr(0) * lfo)
			+ (\env_square_width_mod.kr(0) * modenv);
			var index = \fm_index.kr(0)
			+ (2 * \env_index_mod.kr(0) * modenv)
			+ (20 * \lfo_index_mod.kr(0) * amp_lfo);
			var sq = PulsePTR.ar(
				freq:pitch_sq,
				width:width_sq,
				phase:SinOsc.ar(
					pitch_sq * \fm_numerator.kr(1) / \fm_denominator.kr(1),
					mul:index
				))[0];
			var pitch_form = (note + \detune_formant.kr(0) + pitch_mod).midicps;
			var width_form = \width_formant.kr(0.5)
			+ (0.5 * \lfo_formant_width_mod.kr(0) * lfo)
			+ (\env_formant_width_mod.kr(0) * modenv);
			var form_form = pitch_form * (
				(2 ** \formant.kr(0))
				+ (sq * \square_formant_mod.kr(0))
				+ (lfo * \lfo_formant_mod.kr(0))
				+ (modenv * \env_formant_mod.kr(0))
			);
			var form = SineShaper.ar(
				FormantTriPTR.ar(pitch_form, form_form, width_form)
				* (\formant_amp.kr(0.5) + (sq * \square_formant_amp_mod.kr(0))),
				0.5, 2,
			);
			var snd = (env + amp_lfo) * (form + (\square_amp.kr(0.5) * sq));
			var hifreq = (\highpass_freq.kr(50).cpsmidi
				+ (6 * modenv * \env_highpass_mod.kr(0))
				+ (1.2 * lfo * \lfo_highpass_mod.kr(0))).midicps;
			var lofreq = (\lowpass_freq.kr(10000).cpsmidi
				+ (6 * modenv * \env_lowpass_mod.kr(0))
				+ (1.2 * lfo * \lfo_lowpass_mod.kr(0))).midicps;
			snd = SVF.ar(snd, hifreq, \highpass_resonance.kr(0), lowpass:0, highpass:1);
			snd = SVF.ar(snd, lofreq, \lowpass_resonance.kr(0));
			Out.ar(\out.ir, snd * 0.5 * \amp.kr(0.5));
		}).add;

		xDTimbres = Array.fill(timbralityMax, { xDParameters.deepCopy; });
		xTTimbres = Array.fill(timbralityMax, { xTParameters.deepCopy; });
		xVoices = Dictionary.new;
		xVoicesOn = Dictionary.new;
		pedalSustainNotes = Dictionary.new;
		pedalSostenutoNotes = Dictionary.new;
		
		fnNoteOnMono = {
			arg note, amp, timbre, type;
			var notesOn = false;
			var setNote = false;
			xVoices.keysValuesDo({ arg key, syn;
				if ((key.type==type) && (key.timbre==timbre) && (syn.isPlaying == true), {
					notesOn = true;
				});
			});
			if (notesOn==false, {
				fnNoteOnPoly.(note, amp, type, timbre);
			}, {
				xVoices.keysValuesDo({ arg key, syn;
					if ((key.type==type) && (key.timbre==timbre) && (syn.isPlaying == true), {
						syn.set(\gate, 0);
						if (setNote==false, {
							syn.set(\gate, 1, \note, note);
							setNote = true;
						});
					});
				});
			});
			fnNoteAdd.(note, type, timbre);
		};
		
		fnNoteOnPoly = {
			arg note, amp, timbre, type;
			var key = (note: note, timbre: timbre, type: type);
			if ((type == 0), {
				var def = ("xD2_" ++ (xDTimbres[timbre].alg).asInteger).asString;
				xVoices.put(key,
					Synth.before(endOfChain, def, [
						\out,     outBus,
						\note,    note,
						\amp,     amp * xDTimbres[timbre].amp,
						\gate,    1,
						\num,     xDTimbres[timbre].num,
						\denom,   xDTimbres[timbre].denom,
						\hirat,   xDTimbres[timbre].hirat,
						\lorat,   xDTimbres[timbre].lorat,
						\oamp,    xDTimbres[timbre].oamp,
						\oatk,    xDTimbres[timbre].oatk,
						\fatk,    xDTimbres[timbre].fatk,
						\odec,    xDTimbres[timbre].odec,
						\fdec,    xDTimbres[timbre].fdec,
						\osus,    xDTimbres[timbre].osus,
						\fsus,    xDTimbres[timbre].fsus,
						\orel,    xDTimbres[timbre].orel,
						\frel,    xDTimbres[timbre].frel,
						\hfamt,   xDTimbres[timbre].hfmat,
						\lfamt,   xDTimbres[timbre].lfamt,
						\ocurve,  xDTimbres[timbre].ocurve,
						\fcurve,  xDTimbres[timbre].fcurve,
						\lfreq,   xDTimbres[timbre].lfreq,
						\lfade,   xDTimbres[timbre].lfade,
						\lfo_am,  xDTimbres[timbre].lfo_am,
						\lfo_pm,  xDTimbres[timbre].lfo_pm,
						\lfo_hfm, xDTimbres[timbre].lfo_hfm,
						\lfo_lfm, xDTimbres[timbre].lfo_lfm,
						\feedback,xDTimbres[timbre].feedback
					])
				);
			}, {
				xVoices.put(key,
					Synth.before(endOfChain, "xTurns", [
						\out, outBus,
						\note, note,
						\amp, amp * xTTimbres[timbre].amp,
						\gate, 1,
						\amp_attack, xTTimbres[timbre].amp_attack,
						\amp_decay, xTTimbres[timbre].amp_decay,
						\amp_sustain, xTTimbres[timbre].amp_sustain,
						\amp_release, xTTimbres[timbre].amp_release,
						\mod_attack, xTTimbres[timbre].mod_attack,
						\mod_decay, xTTimbres[timbre].mod_decay,
						\mod_sustain, xTTimbres[timbre].mod_sustain,
						\mod_release, xTTimbres[timbre].mod_release,
						\lfo_freq, xTTimbres[timbre].lfo_freq,
						\lfo_fade, xTTimbres[timbre].lfo_fade,
						\lfo_amp_mod: xTTimbres[timbre].lfo_amp_mod,
						\lfo_pitch_mod: xTTimbres[timbre].lfo_pitch_mod,
						\lfo_square_width_mod: xTTimbres[timbre].lfo_square_width_mod,
						\lfo_index_mod: xTTimbres[timbre].lfo_index_mod,
						\lfo_formant_width_mod: xTTimbres[timbre].lfo_formant_width_mod,
						\lfo_formant_mod: xTTimbres[timbre].lfo_formant_mod,
						\lfo_highpass_mod: xTTimbres[timbre].lfo_highpass_mod,
						\lfo_lowpass_mod: xTTimbres[timbre].lfo_lowpass_mod,
						\env_pitch_mod: xTTimbres[timbre].env_pitch_mod,
						\env_square_width_mod: xTTimbres[timbre].env_square_width_mod,
						\env_index_mod: xTTimbres[timbre].env_index_mod,
						\env_formant_width_mod: xTTimbres[timbre].env_formant_width_mod,
						\env_formant_mod: xTTimbres[timbre].env_formant_mod,
						\env_highpass_mod: xTTimbres[timbre].env_highpass_mod,
						\detune_square: xTTimbres[timbre].detune_square,
						\width_square: xTTimbres[timbre].width_square,
						\fm_index: xTTimbres[timbre].fm_index,
						\fm_numerator: xTTimbres[timbre].fm_numerator,
						\fm_denominator: xTTimbres[timbre].fm_numerator,
						\square_amp: xTTimbres[timbre].square_amp,
						\detune_formant: xTTimbres[timbre].detune_formant,
						\width_formant: xTTimbres[timbre].width_formant,
						\formant: xTTimbres[timbre].formant,
						\square_formant_mod: xTTimbres[timbre].square_formant_mod,
						\formant_amp: xTTimbres[timbre].formant_amp,
						\square_formant_amp_mod: xTTimbres[timbre].square_formant_amp_mod,
						\highpass_freq: xTTimbres[timbre].highpass_freq,
						\highpass_resonance: xTTimbres[timbre].highpass_resonance,
						\lowpass_freq: xTTimbres[timbre].lowpass_freq,
						\lowpass_resonance: xTTimbres[timbre].lowpass_resonance,
					])
				);
			});
			NodeWatcher.register(xVoices.at(key), true);
			fnNoteAdd.(note, timbre, type);
		};
		
		fnNoteAdd = {
			arg note, timbre, type;
			var oldestNote = 0;
			var oldestNoteVal = 10000000;
			polyphonyCount = polyphonyCount + 1;
			xVoicesOn.put((note: note, timbre: timbre, type: type), polyphonyCount);
			if (xVoicesOn.size > polyphonyMax, {
				xVoicesOn.keysValuesDo({ arg key, val;
					if (val < oldestNoteVal, {
						oldestNoteVal = val;
						oldestNote = key;
					});
				});
				("max polyphony reached, removing note " ++ oldestNote).asString.postln;
				fnNoteOff.(oldestNote.note, oldestNote.timbre, oldestNote.type);
			});
		};
		
		fnNoteOn = {
			arg note, amp, timbre, type;
			var key = (note: note, timbre: timbre, type: type);
			if (xVoices.at(key) != nil, {
				fnNoteOff.(note, timbre, type);
			});
			if ((type == 0), {
				if (xDTimbres[timbre].monophonic > 0, {
					fnNoteOnMono.(note, amp, timbre, type);
				}, {
					fnNoteOnPoly.(note, amp, timbre, type);
				});
			}, {
				if (xTTimbres[timbre].monophonic > 0, {
					fnNoteOnMono.(note, amp, timbre, type);
				}, {
					fnNoteOnPoly.(note, amp, timbre, type);
				});
			});
		};
		
		fnNoteOff = {
			arg note, timbre, type;
			if ((type == 0), {
				if (xDTimbres[timbre].monophonic > 0, {
					fnNoteOffMono.(note, timbre, type);
				}, {
					fnNoteOffPoly.(note, timbre, type);
				});	
			}, {
				if (xTTimbres[timbre].monophonic > 0, {
					fnNoteOffMono.(note, timbre, type);
				}, {
					fnNoteOffPoly.(note, timbre, type);
				});
			});
		};
		
		fnNoteOffMono = {
			arg note, timbre, type;
			var notesOn = false;
			var playedAnother = false;
			xVoicesOn.removeAt((note: note, timbre: timbre, type: type));
			xVoicesOn.keysValuesDo({ arg key, val;
				if ((key.timbre==timbre) && (key.type == type), {
					notesOn = true;
				});
			});
			if (notesOn==false, {
				xVoices.keysValuesDo({ arg key, syn;
					if ((key.timbre==timbre) && (key.type == type) && (syn.isPlaying == true), {
						syn.release();
						xVoices.removeAt(key);
					});
				});
			}, {
				xVoices.keysValuesDo({ arg key, syn;
					if ((key.timbre==timbre) && (key.type == type) && (syn.isPlaying == true), {
						syn.release();
						if (playedAnother==false, {
							syn.set(\gate, 1, \note, key.note);
							playedAnother = true;
						});
					});
				});
			});
		};
		
		fnNoteOffPoly = {
			arg note, timbre, type;
			var key = (note: note, timbre: timbre, type: type);
			xVoicesOn.removeAt(key);
			
			if (pedalSustainOn==true, {
				pedalSustainNotes.put(key, 1);
			}, {
				if ((pedalSostenutoOn==true) && (pedalSustainNotes.at(key) != nil),{},{
					if (xVoices.at(key) != nil, {
						xVoices.at(key).release();
						xVoices.removeAt(key);
					});
				});
			});
		};
		
		this.addCommand("note_on", "ifii", { arg msg;
			fnNoteOn.(msg[1], msg[2], msg[3], msg[4]);
		});
		
		this.addCommand("note_off", "iii", { arg msg;
			fnNoteOff.(msg[1], msg[2], msg[3]);
		});
		
		this.addCommand("sustain", "i", { arg msg;
			pedalSustainOn = (msg[1] == 1);
			if (pedalSustainOn==false, {
				pedalSustainNotes.keysValuesDo({ arg key, val;
					if (xVoicesOn.at(key)==nil, {
						pedalSustainNotes.removeAt(key);
						fnNoteOff.(key.note, key.timbre, key.type);
					});
				});
			}, {
				xVoicesOn.keysValuesDo({ arg key, val;
					pedalSustainNotes.put(key, 1);
				});
			});
		});
		
		this.addCommand("sostenuto", "i", {arg msg;
			pedalSostenutoOn = (msg[1] == 1);
			if (pedalSostenutoOn == false, {
				pedalSostenutoNotes.keysValuesDo({ arg key, val;
					if (xVoicesOn.at(key) == nil, {
						pedalSostenutoNotes.removeAt(key);
						fnNoteOff.(key.note, key.timbre, key.type);
					});
				});
			},{
				xVoicesOn.keysValuesDo({ arg key, val;
					pedalSostenutoNotes.put(key, 1);
				});
			});
		});
		
		this.addCommand("set_timbre_monophonic", "iii", { arg msg;
			if (msg[3] == 0, {
				if (msg[1] == 1, {
					xDTimbres[msg[2]].monophonic = 1;
				}, {
					xDTimbres[msg[2]].monophonic = 0;
				});	
			}, {
				if (msg[1] == 1, {
					xTTimbres[msg[2]].monophonic = 1;
				}, {
					xTTimbres[msg[3]].monophonic = 0;
				});
			});
		});
		
		this.addCommand("set_polyphony", "i", { arg msg;
			polyphonyMax = msg[1];
		});
		
		this.addCommand("xDset", "sif", { arg msg;
			var param = msg[1].asSymbol;
			var val = msg[3];
			xDTimbres[msg[2]].put(param, val);
			if (msg[1] == "alg", {}, {
				xVoices.keysValuesDo({ arg key, syn;
					if ((key.type == 0) && (key.timbre == msg[2]) && (syn.isPlaying == true), {
						syn.set(param, val);
					});
				});
			});
		});
		
		this.addCommand("xTset", "sif", { arg msg;
			var param = msg[1].asSymbol;
			var val = msg[3];
			xTTimbres[msg[2]].put(param, val);
			xVoices.keysValuesDo({ arg key, syn;
				if ((key.type != 0) && (key.timbre == msg[2]) && (syn.isPlaying == true), {
					syn.set(param, val);
				});
			});
		});
		
		this.addCommand("xDindex_set", "siif", { arg msg;
			var param = msg[1].asSymbol;
			var index = msg[2] - 1;
			var curr = xDTimbres[msg[3]].at(param);
			curr = Array.fill(6, { arg i;
				if (i == index, {
					msg[4];
				}, {
					curr[i];
				});
			});
			xDTimbres[msg[3]].put(param, curr);
			xVoices.keysValuesDo({ arg key, syn;
				if ((key.type == 0) && (key.timbre == msg[3]) && (syn.isPlaying == true), {
					syn.set(key, curr);
				});
			});
		});
	}
	
	free {
		xVoices.keysValuesDo({ arg key, value; value.free; });
		endOfChain.free;
		outBus.free;
	}
}
