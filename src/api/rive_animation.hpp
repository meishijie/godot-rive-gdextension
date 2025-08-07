#ifndef _RIVEEXTENSION_API_ANIMATION_HPP_
#define _RIVEEXTENSION_API_ANIMATION_HPP_

// godot-cpp
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>

// rive-cpp
#include <rive/animation/linear_animation_instance.hpp>
#include <rive/animation/loop.hpp>

// extension
#include "utils/types.hpp"
#include "utils/godot_macros.hpp"

using namespace godot;

class RiveAnimation : public Resource {
    GDCLASS(RiveAnimation, Resource);
    friend class RiveInstance;

   private:
    rive::ArtboardInstance *artboard;
    Ptr<rive::LinearAnimationInstance> animation;
    int index = -1;
    String name = "";

   protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("exists"), &RiveAnimation::exists);
        ClassDB::bind_method(D_METHOD("get_index"), &RiveAnimation::get_index);
        ClassDB::bind_method(D_METHOD("get_name"), &RiveAnimation::get_name);
        ClassDB::bind_method(D_METHOD("get_duration"), &RiveAnimation::get_duration);
        ClassDB::bind_method(D_METHOD("get_current_time"), &RiveAnimation::get_current_time);
        ClassDB::bind_method(D_METHOD("get_current_direction"), &RiveAnimation::get_current_direction);
        ClassDB::bind_method(D_METHOD("get_loop_mode"), &RiveAnimation::get_loop_mode);
        ClassDB::bind_method(D_METHOD("set_loop_mode", "loop_mode"), &RiveAnimation::set_loop_mode);
        ClassDB::bind_method(D_METHOD("reset", "speed_multiplier"), &RiveAnimation::reset);
    }

   public:
    static Ref<RiveAnimation> MakeRef(
        rive::ArtboardInstance *artboard_value,
        Ptr<rive::LinearAnimationInstance> animation_value,
        int index_value,
        String name_value
    ) {
        if (!artboard_value || !animation_value) return nullptr;
        Ref<RiveAnimation> obj = memnew(RiveAnimation);
        obj->artboard = artboard_value;
        obj->animation = std::move(animation_value);
        obj->index = index_value;
        obj->name = name_value;
        return obj;
    }

    RiveAnimation() {}

    bool exists() const {
        return animation != nullptr;
    }

    int get_index() const {
        return index;
    }

    String get_name() const {
        return name;
    }

    float get_duration() const {
        return animation ? animation->durationSeconds() : -1;
    }

    float get_current_time() const {
        return animation ? animation->time() : -1;
    }

    int get_current_direction() const {
        return animation ? animation->direction() : 1;
    }

    int get_loop_mode() const {
        return animation ? animation->loopValue() : 0;
    }

    void set_loop_mode(int loop_mode) {
        if (animation) {
            animation->loopValue(loop_mode);
            // Set animation loop mode
        }
    }

    void reset(float speed_multiplier = 1.0) {
        if (animation) animation->reset(speed_multiplier);
    }

    String _to_string() const {
        return "RiveAnimation";
    }

    bool operator==(const RiveAnimation &other) const {
        return other.animation == animation;
    }

    bool operator!=(const RiveAnimation &other) const {
        return other.animation != animation;
    }
};

#endif