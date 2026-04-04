# Mix & Match

Most cocktail apps open with the same question: "what do you want to make?" — which only works if you already know. For newcomers, that's where the experience ends.

MixMatch reverses the question. You pick ingredients, adjust the ratios, watch the color blend in real time, and the app tells you what cocktail you've actually created. No prior knowledge needed — you just play, and the learning follows.

For beginners, it works as a low-pressure way to understand flavor balance (sweet, sour, strong, bitter, fruity) and discover classic recipes through exploration. For enthusiasts, it's a sandbox to test combinations and compare against canonical recipes.

Built for Apple Swift Student Challenge 2026.

## Preview

### Demo

<video src="https://github.com/user-attachments/assets/639867bc-edad-4fa2-851d-ad605a89df6f" controls width="600"></video>

### Screenshots
![](screenshots/Simulator%20Screenshot%201.png)
![](screenshots/Simulator%20Screenshot%202.png)
![](screenshots/Simulator%20Screenshot%203.png)
![](screenshots/Simulator%20Screenshot%204.png)

## How it works

1. Browse ingredients by category (Base Spirits / Liqueurs / Bitters & Vermouth / Mixers / Sweeteners) and tap to pour into the shaker
2. Shake your iPad (or tap the button) to mix
3. See which classic cocktail you've matched — with a flavor radar chart, recipe breakdown, and the story behind the drink

## Under the hood

The matching engine uses a generalized cosine similarity with a hand-tuned ingredient substitution matrix — so lime juice and lemon juice aren't treated as completely different ingredients. Signature ingredients (like Campari for Negroni, espresso for Espresso Martini) trigger a dedicated matching path before the general cosine search runs.

## Built with

SwiftUI · AVFoundation · iPad (supports shake gesture via CoreMotion)
