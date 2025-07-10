import * as functions from "firebase-functions";
import OpenAI from "openai";

// Configurazione client OpenAI con API key da Firebase config
const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

export const chatGpt = functions.https.onRequest(async (req, res) => {
  try {
    const prompt = req.body.prompt || "Hello from TravelSage!";

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{role: "user", content: prompt}],
    });

    res.json({reply: completion.choices[0].message.content});
  } catch (error) {
    console.error("Errore nella chiamata OpenAI:", error);
    res.status(500).send("Errore nella chiamata OpenAI");
  }
});

