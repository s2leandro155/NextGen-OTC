/*
 * Copyright (c) 2010-2026 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

#include "irenderbackend.h"

class PainterShaderProgram;

/*
 * GLBackend - the OpenGL consumer of a RenderFrame.
 *
 * This is the migration's control experiment. Metal does not exist yet; what exists is a
 * renderer whose behaviour is the reference, and the only way to know whether the frame model
 * describes that behaviour is to make the reference renderer run on it and compare the pixels.
 * If GLBackend cannot reproduce the legacy path exactly, the model is wrong, and it is far
 * cheaper to learn that here than from a Metal backend that also has its own bugs.
 *
 * IT DRAWS THROUGH `Painter`, ON PURPOSE. Painter owns the blend table, the scissor y-flip,
 * the colour mask, the projection and the whole uniform-upload sequence, all of which are
 * exactly what has to stay identical. Reimplementing them beside the original would create two
 * versions of the thing under test. So the split is: this class owns everything the frame model
 * added - passes, targets, load actions, materials, handle resolution, geometry slices - and
 * Painter stays the draw primitive underneath. When the legacy path is deleted, Painter's
 * remaining pieces are inlined here; until then, one implementation means one behaviour.
 *
 * The pieces this class genuinely owns and Painter never had:
 *   - render targets as pass state, rather than an FBO bind buried in a callback;
 *   - LoadAction, including the two different clears GL uses (a glClear and a blended quad);
 *   - MaterialHandle -> program resolution, including the built-ins ShaderManager never saw;
 *   - the MaterialParams block, uploaded onto the legacy uniform slots;
 *   - blend enable/disable, which was three scattered glDisable(GL_BLEND) calls;
 *   - readback as a request with a top-left result, rather than three glReadPixels sites.
 */
class GLBackend final : public IRenderBackend
{
public:
    bool initialize() override;
    void shutdown() override;
    void resize(const Size& drawableSize) override;
    bool render(const RenderFrame& frame) override;
    bool readPixels(const ReadbackRequest& request, ReadbackResult& out) override;

    [[nodiscard]] const char* name() const override { return "gl"; }

private:
    void applyUploads(const RenderFrame& frame);
    void runPass(const RenderPass& pass);
    void drawPacket(const RenderPass& pass, const DrawPacket& packet);

    // Null means "let Painter pick", which is what it already does for the two default
    // built-ins based on whether the draw is textured.
    [[nodiscard]] PainterShaderProgram* resolveMaterial(MaterialHandle material) const;

    void setBlendEnabled(bool enabled);

    bool m_blendEnabled{ true };
    bool m_loggedMissingMaterial{ false };
    bool m_loggedMissingTarget{ false };
};
