#ifndef _RIVEEXTENSION_SKIA_INSTANCE_HPP_
#define _RIVEEXTENSION_SKIA_INSTANCE_HPP_

// godot-cpp
#include <godot_cpp/variant/builtin_types.hpp>

// skia
#include <skia/dependencies/skia/include/core/SkBitmap.h>
#include <skia/dependencies/skia/include/core/SkCanvas.h>
#include <skia/dependencies/skia/include/core/SkSurface.h>

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
        SkPixmap pixmap;
        PackedByteArray bytes;
        if (!surface) {
            return bytes;
        }
        if (!surface->peekPixels(&pixmap)) {
            return bytes;
        }
        auto info = pixmap.info();
        
        // Copy pixel data
        size_t bytes_per_pixel = info.bytesPerPixel();
        size_t row_bytes = pixmap.rowBytes();
        
        bytes.resize(row_bytes * info.height());
        
        // Sample a few pixels to check if they have data
        uint32_t non_zero_count = 0;
        uint32_t sample_pixels[4] = {0};
        int sample_count = 0;
        uint32_t min_alpha = 255, max_alpha = 0;
        
        for (int y = 0; y < info.height(); y++) {
            for (int x = 0; x < info.width(); x++) {
                int offset = y * row_bytes + x * bytes_per_pixel;
                auto addr = pixmap.addr32(x, y);
                uint32_t pixel_value = *addr;
                bytes.encode_u32(offset, pixel_value);
                
                if (pixel_value != 0) {
                    non_zero_count++;
                    
                    // Extract alpha channel (highest 8 bits)
                    uint32_t alpha = (pixel_value >> 24) & 0xFF;
                    if (alpha < min_alpha) min_alpha = alpha;
                    if (alpha > max_alpha) max_alpha = alpha;
                    
                    // Sample diverse pixels: different areas and alpha values
                    if (sample_count < 4) {
                        // Sample from different quadrants and alpha ranges
                        bool should_sample = false;
                        if (sample_count == 0) should_sample = true; // First non-zero
                        else if (sample_count == 1 && alpha > 128) should_sample = true; // High alpha
                        else if (sample_count == 2 && (x > info.width()/2 || y > info.height()/2)) should_sample = true; // Different area
                        else if (sample_count == 3 && alpha != (sample_pixels[0] >> 24)) should_sample = true; // Different alpha
                        
                        if (should_sample) {
                            sample_pixels[sample_count] = pixel_value;
                            sample_count++;
                        }
                    }
                }
            }
        }
        
        // Debug: Pixel analysis completed
        
        return bytes;
    }

    void clear() {
        if (surface && renderer) surface->getCanvas()->clear(SkColors::kTransparent);
    }

   private:
    void on_transform_changed() {
        surface = SkSurfaces::Raster(image_info());
        renderer = rivestd::make_unique<SkiaRenderer>(surface->getCanvas());
    }
};

#endif