{
  "name": "Fb2",
  "nodes": [
    {
      "parameters": {
        "chatId": "1629769618",
        "text": "={{ $('Merge').item.json.file }}\n{{ $('Merge').item.json.title }}\n{{ $('Merge').item.json.authors }}\n{{ $('Merge').item.json.genres }}\n{{ $('Merge').item.json.annotation }}\n",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        1248,
        336
      ],
      "id": "f8ea1f11-b733-4ff1-b523-4609aa463abd",
      "name": "Send a text message",
      "webhookId": "17db26c4-c2ac-43bb-9727-21e22c20b35d",
      "credentials": {
        "telegramApi": {
          "id": "vzuFATaCk5xtPEhe",
          "name": "Telegram account 2"
        }
      }
    },
    {
      "parameters": {
        "formTitle": "Sumbit FB2 file",
        "formFields": {
          "values": [
            {
              "fieldLabel": "file",
              "fieldType": "file",
              "multipleFiles": false,
              "acceptFileTypes": ".fb2",
              "requiredField": true
            }
          ]
        },
        "options": {}
      },
      "type": "n8n-nodes-base.formTrigger",
      "typeVersion": 2.3,
      "position": [
        -224,
        320
      ],
      "id": "90bef1b3-225e-4ed6-a6c7-25ccb8cb9ad6",
      "name": "On form submission",
      "webhookId": "3a44054f-8182-4832-a560-2a5ef304567c"
    },
    {
      "parameters": {
        "operation": "xml",
        "binaryPropertyName": "=file",
        "options": {}
      },
      "type": "n8n-nodes-base.extractFromFile",
      "typeVersion": 1,
      "position": [
        0,
        320
      ],
      "id": "1b983808-3bc9-4209-8ac2-56b09401be00",
      "name": "Extract from File"
    },
    {
      "parameters": {
        "model": {
          "__rl": true,
          "value": "gpt-4.1-mini",
          "mode": "list",
          "cachedResultName": "gpt-4.1-mini"
        },
        "options": {}
      },
      "type": "@n8n/n8n-nodes-langchain.lmChatOpenAi",
      "typeVersion": 1.2,
      "position": [
        464,
        752
      ],
      "id": "64f7a95e-a183-4f62-b2d2-4db787d99788",
      "name": "OpenAI Chat Model",
      "credentials": {
        "openAiApi": {
          "id": "6pilFxSUHyO7eKRs",
          "name": "OpenAi account"
        }
      }
    },
    {
      "parameters": {
        "options": {
          "summarizationMethodAndPrompts": {
            "values": {
              "combineMapPrompt": "Write a concise summary in Russian language of the following:\n\n\n\"{text}\"\n\n\nCONCISE SUMMARY:",
              "prompt": "=Write a concise summary in Russian language of the following:\n\n\n\"{text}\"\n\n\nCONCISE SUMMARY:"
            }
          },
          "batching": {
            "delayBetweenBatches": 3000
          }
        }
      },
      "type": "@n8n/n8n-nodes-langchain.chainSummarization",
      "typeVersion": 2.1,
      "position": [
        464,
        480
      ],
      "id": "333d5ea9-c1ad-4f88-ac1f-6fbf32435022",
      "name": "Summarization Chain"
    },
    {
      "parameters": {
        "command": "=# Create a temp text file\ntemp_file=$(mktemp /tmp/tts_XXXX.txt)\necho \"{{ $json.text }}\" > \"$temp_file\"\n\n# Generate WAV using espeak-ng\nespeak-ng -v ru -f \"$temp_file\" -w \"/tmp/tts.wav\"\n\n# Convert WAV to MP3\nlame \"/tmp/tts.wav\" \"/home/mike/Documents/fb2/Voice/{{ $json.file }}.mp3\"\n\n# Clean up temp files\nrm \"$temp_file\" \"/tmp/tts.wav\"\n"
      },
      "type": "n8n-nodes-base.executeCommand",
      "typeVersion": 1,
      "position": [
        1024,
        336
      ],
      "id": "1c21ebe0-bf7b-43c0-8e5b-db8880c63b11",
      "name": "Execute Command"
    },
    {
      "parameters": {
        "jsCode": "\n\nfunction getTagValues(xml, tag) {\n  const regex = new RegExp(`<${tag}[^>]*>([\\\\s\\\\S]*?)<\\\\/${tag}>`, \"gi\");\n  const results = [];\n  let match;\n  while ((match = regex.exec(xml)) !== null) {\n    results.push(match[1].trim());\n  }\n  return results;\n}\n\n\n\nreturn (async () => {\n  const xml = $json.data || $json.file || \"\";\n\n  // Title\n  const titleArr = getTagValues(xml, \"book-title\");\n  const title = titleArr.length ? titleArr[0] : \"Unknown Title\";\n\n  // Authors\n  const authorBlocks = getTagValues(xml, \"author\");\n  const authors = authorBlocks.map(block => {\n    const first = getTagValues(block, \"first-name\")[0] || \"\";\n    const middle = getTagValues(block, \"middle-name\")[0] || \"\";\n    const last = getTagValues(block, \"last-name\")[0] || \"\";\n    const full = [first, middle, last].filter(Boolean).join(\" \").trim();\n    return full;\n  }).filter(Boolean);\n\n  // Genres\n  const genres = getTagValues(xml, \"genre\");\n\n  // Annotation\n  const annotationBlocks = getTagValues(xml, \"annotation\");\n  const annotation = annotationBlocks\n    .join(\" \")\n    .replace(/<[^>]+>/g, \"\")\n    .replace(/\\s+/g, \" \")\n    .trim() || \"No description\";\n\n  // Date\n  const date = getTagValues(xml, \"date\")[0] || \"\";\n\n  // Language\n  const lang = getTagValues(xml, \"lang\")[0] || \"\";\n\n  // --- Full Text Extraction ---\n  const bodyBlocks = getTagValues(xml, \"body\");\n  const paragraphs = [];\n\n  bodyBlocks.forEach(body => {\n    const ps = getTagValues(body, \"p\");\n    ps.forEach(p => {\n      const clean = p.replace(/<[^>]+>/g, \"\").replace(/\\s+/g, \" \").trim();\n      if (clean) paragraphs.push(clean);\n    });\n  });\n\n\n  \n  const fullText = paragraphs.join(\"\\n\\n\"); // readable paragraphs separated by blank lines\n\n  const fileName = $('On form submission').first().json.file.filename;\n\n  return [{\n    json: {\n      title,\n      authors,\n      genres,\n      annotation,\n      date,\n      lang,\n      file: fileName,\n      text: fullText\n    }\n  }];\n})();\n"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        224,
        320
      ],
      "id": "259a0fed-9198-4fc2-a020-8e01e373cc53",
      "name": "Parse FB2"
    },
    {
      "parameters": {
        "mode": "combine",
        "combineBy": "combineByPosition",
        "options": {}
      },
      "type": "n8n-nodes-base.merge",
      "typeVersion": 3.2,
      "position": [
        800,
        336
      ],
      "id": "3f72d648-2621-4a74-bf67-95dfccb30209",
      "name": "Merge"
    }
  ],
  "pinData": {},
  "connections": {
    "On form submission": {
      "main": [
        [
          {
            "node": "Extract from File",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Extract from File": {
      "main": [
        [
          {
            "node": "Parse FB2",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "OpenAI Chat Model": {
      "ai_languageModel": [
        [
          {
            "node": "Summarization Chain",
            "type": "ai_languageModel",
            "index": 0
          }
        ]
      ]
    },
    "Summarization Chain": {
      "main": [
        [
          {
            "node": "Merge",
            "type": "main",
            "index": 1
          }
        ]
      ]
    },
    "Send a text message": {
      "main": [
        []
      ]
    },
    "Parse FB2": {
      "main": [
        [
          {
            "node": "Summarization Chain",
            "type": "main",
            "index": 0
          },
          {
            "node": "Merge",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Execute Command": {
      "main": [
        [
          {
            "node": "Send a text message",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Merge": {
      "main": [
        [
          {
            "node": "Execute Command",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "versionId": "56829cfb-5078-4fcb-8d97-58ae80cd4015",
  "meta": {
    "templateCredsSetupCompleted": true,
    "instanceId": "dae826cbf806e76f879796dd5b506b99ee08f90440c85f2b42e963933ca20a50"
  },
  "id": "ZRghaTFrj7wrQutY",
  "tags": []
}
