package arm.ui;

import zui.Zui;
import zui.Nodes;
import iron.data.Data;
import iron.system.Time;
import iron.system.Input;
import arm.io.ImportAsset;
import arm.sys.Path;
import arm.sys.File;
import arm.ProjectBaseFormat;

class TabTextures {

	@:access(zui.Zui)
	public static function draw(htab: Handle) {
		var ui = UIBase.inst.ui;
		var statush = Config.raw.layout[LayoutStatusH];
		if (ui.tab(htab, tr("Textures")) && statush > UIStatus.defaultStatusH * ui.SCALE()) {

			ui.beginSticky();
			if (Config.raw.touch_ui) {
				ui.row([1 / 4, 1 / 4]);
			}
			else {
				ui.row([1 / 14, 1 / 14]);
			}

			if (ui.button(tr("Import"))) {
				UIFiles.show(Path.textureFormats.join(","), false, true, function(path: String) {
					ImportAsset.run(path, -1.0, -1.0, true, false);
					UIBase.inst.hwnds[2].redraws = 2;
				});
			}
			if (ui.isHovered) ui.tooltip(tr("Import texture file") + ' (${Config.keymap.file_import_assets})');

			if (ui.button(tr("2D View"))) UIBase.inst.show2DView(View2DAsset);

			ui.endSticky();

			if (Project.assets.length > 0) {

				var statusw = kha.System.windowWidth() - UIToolbar.inst.toolbarw - Config.raw.layout[LayoutSidebarW];
				var slotw = Std.int(52 * ui.SCALE());
				var num = Std.int(statusw / slotw);

				for (row in 0...Std.int(Math.ceil(Project.assets.length / num))) {
					var mult = Config.raw.show_asset_names ? 2 : 1;
					ui.row([for (i in 0...num * mult) 1 / num]);

					ui._x += 2;
					var off = Config.raw.show_asset_names ? ui.ELEMENT_OFFSET() * 10.0 : 6;
					if (row > 0) ui._y += off;

					for (j in 0...num) {
						var imgw = Std.int(50 * ui.SCALE());
						var i = j + row * num;
						if (i >= Project.assets.length) {
							@:privateAccess ui.endElement(imgw);
							if (Config.raw.show_asset_names) @:privateAccess ui.endElement(0);
							continue;
						}

						var asset = Project.assets[i];
						var img = Project.getImage(asset);
						var uix = ui._x;
						var uiy = ui._y;
						var sw = img.height < img.width ? img.height : 0;
						if (ui.image(img, 0xffffffff, slotw, 0, 0, sw, sw) == State.Started && ui.inputY > ui._windowY) {
							var mouse = Input.getMouse();
							App.dragOffX = -(mouse.x - uix - ui._windowX - 3);
							App.dragOffY = -(mouse.y - uiy - ui._windowY + 1);
							App.dragAsset = asset;
							Context.raw.texture = asset;

							if (Time.time() - Context.raw.selectTime < 0.25) UIBase.inst.show2DView(View2DAsset);
							Context.raw.selectTime = Time.time();
							UIView2D.inst.hwnd.redraws = 2;
						}

						if (asset == Context.raw.texture) {
							var _uix = ui._x;
							var _uiy = ui._y;
							ui._x = uix;
							ui._y = uiy;
							var off = i % 2 == 1 ? 1 : 0;
							var w = 50;
							ui.fill(0,               0, w + 3,       2, ui.t.HIGHLIGHT_COL);
							ui.fill(0,     w - off + 2, w + 3, 2 + off, ui.t.HIGHLIGHT_COL);
							ui.fill(0,               0,     2,   w + 3, ui.t.HIGHLIGHT_COL);
							ui.fill(w + 2,           0,     2,   w + 4, ui.t.HIGHLIGHT_COL);
							ui._x = _uix;
							ui._y = _uiy;
						}

						if (ui.isHovered) {
							ui.tooltipImage(img, 256);
							ui.tooltip(asset.name);
						}

						if (ui.isHovered && ui.inputReleasedR) {
							Context.raw.texture = asset;
							var isPacked = Project.raw.packed_assets != null && Project.packedAssetExists(Project.raw.packed_assets, asset.file);
							UIMenu.draw(function(ui: Zui) {
								ui.text(asset.name + (isPacked ? " " + tr("(packed)") : ""), Right, ui.t.HIGHLIGHT_COL);
								if (ui.button(tr("Export"), Left)) {
									UIFiles.show("png", true, false, function(path: String) {
										App.notifyOnNextFrame(function () {
											if (App.pipeMerge == null) App.makePipe();
											var target = kha.Image.createRenderTarget(to_pow2(img.width), to_pow2(img.height));
											target.g2.begin(false);
											target.g2.pipeline = App.pipeCopy;
											target.g2.drawScaledImage(img, 0, 0, target.width, target.height);
											target.g2.pipeline = null;
											target.g2.end();
											App.notifyOnNextFrame(function () {
												var f = UIFiles.filename;
												if (f == "") f = tr("untitled");
												if (!f.endsWith(".png")) f += ".png";
												Krom.writePng(path + Path.sep + f, target.getPixels().getData(), target.width, target.height, 0);
												target.unload();
											});
										});
									});
								}
								if (ui.button(tr("Reimport"), Left)) {
									Project.reimportTexture(asset);
								}
								if (ui.button(tr("To Mask"), Left)) {
									App.notifyOnNextFrame(function() {
										App.createImageMask(asset);
									});
								}
								if (ui.button(tr("Set as Envmap"), Left)) {
									App.notifyOnNextFrame(function() {
										arm.io.ImportEnvmap.run(asset.file, img);
									});
								}
								if (ui.button(tr("Set as Color ID Map"), Left)) {
									Context.raw.colorIdHandle.position = i;
									Context.raw.colorIdPicked = false;
									UIToolbar.inst.toolbarHandle.redraws = 1;
									if (Context.raw.tool == ToolColorId) {
										UIHeader.inst.headerHandle.redraws = 2;
										Context.raw.ddirty = 2;
									}
								}
								if (ui.button(tr("Delete"), Left, "delete")) {
									deleteTexture(asset);
								}
								if (!isPacked && ui.button(tr("Open Containing Directory..."), Left)) {
									File.start(asset.file.substr(0, asset.file.lastIndexOf(Path.sep)));
								}
								if (!isPacked && ui.button(tr("Open in Browser"), Left)) {
									TabBrowser.showDirectory(asset.file.substr(0, asset.file.lastIndexOf(Path.sep)));
								}
							}, isPacked ? 7 : 9);
						}

						if (Config.raw.show_asset_names) {
							ui._x = uix;
							ui._y += slotw * 0.9;
							ui.text(Project.assets[i].name, Center);
							if (ui.isHovered) ui.tooltip(Project.assets[i].name);
							ui._y -= slotw * 0.9;
							if (i == Project.assets.length - 1) {
								ui._y += j == num - 1 ? imgw : imgw + ui.ELEMENT_H() + ui.ELEMENT_OFFSET();
							}
						}
					}
				}
			}
			else {
				var img = Res.get("icons.k");
				var r = Res.tile50(img, 0, 1);
				ui.image(img, ui.t.BUTTON_COL, r.h, r.x, r.y, r.w, r.h);
				if (ui.isHovered) ui.tooltip(tr("Drag and drop files here"));
			}

			var inFocus = ui.inputX > ui._windowX && ui.inputX < ui._windowX + ui._windowW &&
						  ui.inputY > ui._windowY && ui.inputY < ui._windowY + ui._windowH;
			if (inFocus && ui.isDeleteDown && Project.assets.length > 0 && Project.assets.indexOf(Context.raw.texture) >= 0) {
				ui.isDeleteDown = false;
				deleteTexture(Context.raw.texture);
			}
		}
	}

	static function to_pow2(i: Int): Int {
		i--;
		i |= i >> 1;
		i |= i >> 2;
		i |= i >> 4;
		i |= i >> 8;
		i |= i >> 16;
		i++;
		return i;
	}

	static function updateTexturePointers(nodes: Array<TNode>, i: Int) {
		for (n in nodes) {
			if (n.type == "TEX_IMAGE") {
				if (n.buttons[0].default_value == i) {
					n.buttons[0].default_value = 9999; // Texture deleted, use pink now
				}
				else if (n.buttons[0].default_value > i) {
					n.buttons[0].default_value--; // Offset by deleted texture
				}
			}
		}
	}

	static function deleteTexture(asset: TAsset) {
		var i = Project.assets.indexOf(asset);
		if (Project.assets.length > 1) {
			Context.raw.texture = Project.assets[i == Project.assets.length - 1 ? i - 1 : i + 1];
		}
		UIBase.inst.hwnds[2].redraws = 2;

		if (Context.raw.tool == ToolColorId && i == Context.raw.colorIdHandle.position) {
			UIHeader.inst.headerHandle.redraws = 2;
			Context.raw.ddirty = 2;
			Context.raw.colorIdPicked = false;
			UIToolbar.inst.toolbarHandle.redraws = 1;
		}
		Data.deleteImage(asset.file);
		Project.assetMap.remove(asset.id);
		Project.assets.splice(i, 1);
		Project.assetNames.splice(i, 1);
		function _next() {
			arm.shader.MakeMaterial.parsePaintMaterial();
			arm.util.RenderUtil.makeMaterialPreview();
			UIBase.inst.hwnds[1].redraws = 2;
		}
		App.notifyOnNextFrame(_next);
		for (m in Project.materials) updateTexturePointers(m.canvas.nodes, i);
		for (b in Project.brushes) updateTexturePointers(b.canvas.nodes, i);
	}
}
