---
name: "ultra-realistic-portrait"
description: "Write standalone prompts for ultra-realistic portrait or fashion-editorial images that keep the person from an uploaded reference photo, one image per prompt."
---

# Ultra-Realistic Portrait Prompts

Use this when the user wants image-generation prompts for photorealistic portraits, fashion editorials or ethnic-wear catalogue shots based on their own uploaded reference photo. Other theme skills (for example `navratri-photoshoot`) build on the rules here.

## Golden rules

1. **One image per prompt.** Never write collage, grid, frame-position ("top-left") or border instructions. Each shot is its own prompt.
2. **Every prompt stands alone.** Image models don't remember earlier prompts, so repeat the full outfit, jewelry, setting and lighting in every shot.
3. **Identity lock first.** Every prompt opens with the identity lock below, word for word.
4. **Fixed order:** Identity lock -> Outfit -> Jewelry & beauty -> Setting -> Pose -> Camera & light -> Realism tail.
5. **Concrete poses.** Say where each hand is, the head angle, where she is looking, and her expression. Avoid vague words like "nice pose".
6. **Remind the user** to attach the same reference photo with every prompt.

## Identity lock (copy verbatim)

> Create an ultra-realistic photo using my uploaded reference photo as the SOLE identity reference. Preserve the exact same person: face, facial features, skin tone, body type and natural appearance. Do not beautify, slim, de-age or alter her identity.

## Realism tail (end of every prompt)

> Real DSLR photography, natural skin texture with visible pores, true-to-life fabric and embroidery detail, accurate hands with five fingers, no plastic or airbrushed look, no text, no watermark, single image, not a collage.

## Camera presets

| Shot type | Lens & aperture | Notes |
|---|---|---|
| Close-up | 85mm, f/1.8 | Face and jewelry sharp, creamy background |
| Half-body / medium | 85mm, f/2 | Waist up, soft background blur |
| Three-quarter | 50mm, f/2.2 | Knees up, show outfit drape |
| Full-body | 50mm, f/2.8 | Head to toe, outfit fully visible |
| Wide hero | 35mm, f/4 | Full body plus the setting |

## Lighting presets

- **Golden afternoon:** warm low sun, soft leaf shadows, gentle rim light on hair.
- **Soft window:** diffused side light, gentle shadows, calm mood.
- **Festive bokeh:** warm golden fairy-light bokeh behind the subject, cinematic depth of field.
- **Diya glow:** warm flame light from below/side illuminating the face, dark warm surroundings.
- **Night dramatic:** warm fire light on the subject, cool string-light bokeh behind.
- **Cinematic editorial:** controlled key light, coloured accent light matching the outfit.

## Shot library (pick 3-4 for a set)

- **Close-up:** direct eye contact, one hand near the face holding a prop or touching an earring.
- **Half-body over-the-shoulder:** back turned about 45 degrees, looking over the shoulder at camera, slight smile.
- **Three-quarter twist:** slight body twist, one arm extended, natural smile, hair or fabric in motion.
- **Full-body editorial:** weight on one leg, soft S-curve, outfit fully spread, confident expression.
- **Seated:** on steps, a bench or the floor, body angled, one hand resting, one hand adjusting jewelry.
- **Candid walking:** mid-step, holding the dupatta or pallu, looking away from camera.
- **Devotional / quiet:** folded hands or eyes softly closed, peaceful expression.

## Workflow

1. If not given, ask in one message: the occasion or theme, the outfit (garment, colours, work), the setting, and how many shots (default 4: close-up, half-body, three-quarter, full-body).
2. Build each prompt in the fixed order using the presets above.
3. Output each shot as a short heading (e.g. "Shot 1 - Close-up") followed by the prompt in its own code block so it copies cleanly on mobile.
4. End with one line: attach the same reference photo to every prompt and generate them one at a time.

## Worked example: South Indian Courtyard saree set

Shared look: premium Pinterest-style luxury Indian ethnic catalogue photo; minimal South Indian courtyard with cream plaster walls, terracotta pots and subtle leaf shadows; warm golden afternoon sunlight; 85mm lens, f/2.

- **Shot 1 - Sunlight & Shadows:** Medium close-up angled slightly upward. Standing at a 25-degree angle, head tilted up toward the light, chin slightly lifted. Loose hair strands partially cover her eyes for a candid mood. One hand holds the saree pallu to her chest, the other softly touches the fabric. Traditional ring visible. Saree border crosses the frame diagonally.
- **Shot 2 - Over the Shoulder:** Medium portrait at eye level, soft background blur. Back turned 45 degrees from camera, looking over her left shoulder directly at camera with a subtle playful smile. Long flowing hair with flowers. Right arm bends across the front with the back of her hand just beneath her chin.
- **Shot 3 - Shielding Sun:** Medium portrait, slight side angle. One forearm lifted across her forehead as if shielding her eyes from the sun, making elegant diagonal lines. Other hand lifted gracefully near the shoulder. Head tilted back slightly, eyes softly closed. Cinematic rim lighting on hair.
- **Shot 4 - Full Length Drape:** Full-length, entire saree visible head to toe, standing beside a rustic wooden bench against a cream wall. Soft S-curve, weight on one leg, head tilted down toward the pleats. One hand adjusts the pleats near the knees, the other arm hangs naturally.