#ifndef _RIVEEXTENSION_SKIA_INSTANCE_HPP_
#define _RIVEEXTENSION_SKIA_INSTANCE_HPP_

// stdlib
#include <cstdio>

#include <cstring>

// godot-cpp
#include <godot_cpp/variant/builtin_types.hpp>

// skia
#include "include/core/SkBitmap.h"
#include "include/core/SkCanvas.h"
#include "include/core/SkSurface.h"

#include <skia/renderer/include/skia_factory.hpp>
#include <skia/renderer/include/skia_renderer.hpp>

// extension
#include "utils/types.hpp"
#include "viewer_props.hpp"

using namespace godot;
using namespace rive;

struct SkiaInstance {
    ViewerProps *props;
    sk_sp<SkSurface> surface;
    Ptr<SkiaRenderer> renderer;
    Ptr<SkiaFactory> factory = rivestd::make_unique<SkiaFactory>();

    void set_props(ViewerProps *props_value) {
        props = props_value;
        if (props) {
            props->on_transform_changed([this]() { on_transform_changed(); });
        }
    }

    SkImageInfo image_info() const {
        return SkImageInfo::Make(
            props ? props->width() : 1,
            props ? props->height() : 1,
            SkColorType::kRGBA_8888_SkColorType,
            SkAlphaType::kUnpremul_SkAlphaType
        );
    }

    PackedByteArray bytes() const {
        PackedByteArray out;
        if (!surface) return out;
        SkPixmap pm;
        if (!surface->peekPixels(&pm)) return out;
        const auto info = pm.info();
        const int w = info.width();
        const int h = info.height();
        const size_t bpp = info.bytesPerPixel();
        const size_t tight_row = (size_t)w * bpp;
        out.resize(tight_row * h);
        uint8_t *dst = out.ptrw();
        const uint8_t *src = static_cast<const uint8_t *>(pm.addr());
        if (pm.rowBytes() == tight_row) {
            // 连续内存，整块复制
            if (src && dst && tight_row * h) {
                memcpy(dst, src, tight_row * h);
            }
        } else {
            // 非紧凑行距，逐行复制到紧凑缓冲
            for (int y = 0; y < h; ++y) {
                const uint8_t *row_src = static_cast<const uint8_t *>(pm.addr(0, y));
                uint8_t *row_dst = dst + (size_t)y * tight_row;
                if (row_src) memcpy(row_dst, row_src, tight_row);
            }
        }
        return out;
    }

    void clear() {
        if (surface && renderer) surface->getCanvas()->clear(SkColors::kTransparent);
    }

   private:
    void on_transform_changed() {
        auto info = image_info();
        bool need_recreate = !surface || surface->width() != info.width() || surface->height() != info.height();
        if (need_recreate) {
            surface = SkSurfaces::Raster(info);
            if (!surface) {
                printf("[RiveViewer] ERROR: Failed to create SkSurface with dimensions %dx%d\n", info.width(), info.height());
                renderer.reset();
                return;
            }
            renderer = rivestd::make_unique<SkiaRenderer>(surface->getCanvas());
            if (!renderer) {
                printf("[RiveViewer] ERROR: Failed to create SkiaRenderer\n");
            } else {
                printf("[RiveViewer] SUCCESS: Created renderer with surface %dx%d\n", info.width(), info.height());
            }
        }
    }
};

#endif