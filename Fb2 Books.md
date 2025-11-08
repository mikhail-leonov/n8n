{
  "name": "Fb2",
  "nodes": [
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
        -1760,
        336
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
        -1536,
        336
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
        2080,
        944
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
        2080,
        672
      ],
      "id": "333d5ea9-c1ad-4f88-ac1f-6fbf32435022",
      "name": "Summarization Chain"
    },
    {
      "parameters": {
        "jsCode": "\n\nfunction getTagValues(xml, tag) {\n  const regex = new RegExp(`<${tag}[^>]*>([\\\\s\\\\S]*?)<\\\\/${tag}>`, \"gi\");\n  const results = [];\n  let match;\n  while ((match = regex.exec(xml)) !== null) {\n    results.push(match[1].trim());\n  }\n  return results;\n}\n\n\n\nreturn (async () => {\n  const xml = $json.data || $json.file || \"\";\n\n  // Title\n  const titleArr = getTagValues(xml, \"book-title\");\n  const title = titleArr.length ? titleArr[0] : \"Unknown Title\";\n\n  // Authors\n  const authorBlocks = getTagValues(xml, \"author\");\n  const authors = authorBlocks.map(block => {\n    const first = getTagValues(block, \"first-name\")[0] || \"\";\n    const middle = getTagValues(block, \"middle-name\")[0] || \"\";\n    const last = getTagValues(block, \"last-name\")[0] || \"\";\n    const full = [first, middle, last].filter(Boolean).join(\" \").trim();\n    return full;\n  }).filter(Boolean);\n\n  // Genres\n  const genres = getTagValues(xml, \"genre\");\n\n  // Annotation\n  const annotationBlocks = getTagValues(xml, \"annotation\");\n  const annotation = annotationBlocks\n    .join(\" \")\n    .replace(/<[^>]+>/g, \"\")\n    .replace(/\\s+/g, \" \")\n    .trim() || \"No description\";\n\n  // Date\n  const date = getTagValues(xml, \"date\")[0] || \"\";\n\n  // Language\n  const lang = getTagValues(xml, \"lang\")[0] || \"\";\n\n  // --- Full Text Extraction ---\n  const bodyBlocks = getTagValues(xml, \"body\");\n  const paragraphs = [];\n\n  bodyBlocks.forEach(body => {\n    const ps = getTagValues(body, \"p\");\n    ps.forEach(p => {\n      const clean = p.replace(/<[^>]+>/g, \"\").replace(/\\s+/g, \" \").trim();\n      if (clean) paragraphs.push(clean);\n    });\n  });\n\n\n  \n  const fullText = paragraphs.join(\"\\n\\n\"); // readable paragraphs separated by blank lines\n\n  const fileName = $('On form submission').first().json.file.filename.replace(/[^a-zA-Z0-9а-яА-ЯёЁ _.-]/g, \"\") \n  .replace(/\\s+/g, \"_\") \n  .replace(/_+/g, \"_\") \n  .trim();\n  \n  \n  return [{\n    json: {\n      title,\n      authors,\n      genres,\n      annotation,\n      date,\n      lang,\n      file: fileName,\n      text: fullText\n    }\n  }];\n})();\n"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -1312,
        336
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
        2400,
        544
      ],
      "id": "3f72d648-2621-4a74-bf67-95dfccb30209",
      "name": "Merge"
    },
    {
      "parameters": {
        "rules": {
          "values": [
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "leftValue": "={{ Array.isArray($json.forbiddenTitles) && $json.title \n    ? ($json.forbiddenTitles.some(sub => $json.title.includes(sub)) ? 1 : 0)\n    : 0 }}\n",
                    "rightValue": 1,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    },
                    "id": "7b5be8d3-a7f3-4d30-a561-b8b8b687b92a"
                  }
                ],
                "combinator": "and"
              }
            },
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "id": "cf293b3c-9e64-479e-ab29-3a90e705a6a0",
                    "leftValue": "={{ Array.isArray($json.forbiddenTitles) && $json.title \n    ? ($json.forbiddenTitles.some(sub => $json.title.includes(sub)) ? 1 : 0)\n    : 0 }}\n",
                    "rightValue": 0,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    }
                  }
                ],
                "combinator": "and"
              }
            }
          ]
        },
        "looseTypeValidation": true,
        "options": {}
      },
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3.2,
      "position": [
        -640,
        336
      ],
      "id": "5956acd5-1a98-4887-b7d8-6a5fbb27229a",
      "name": "Filter By Title"
    },
    {
      "parameters": {
        "chatId": "1629769618",
        "text": "={{ $('Parse FB2').item.json.title }} \nIs filtered by the title\n{{ $json.forbiddenTitles }}",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        -416,
        256
      ],
      "id": "085f0db8-0fae-42ff-8bc8-28503fe9248d",
      "name": "Filtered by Title",
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
        "jsCode": "return [\n  {\n    json: {\n      forbiddenTitles: [\"apple\",  \"banana\"]\n    }\n  }\n];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -1088,
        480
      ],
      "id": "c7e2d65d-3a2d-45e1-882e-cd9f066e48ee",
      "name": "Forbidden Titles"
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
        -864,
        336
      ],
      "id": "7e0a1b11-19f4-41cd-a561-dfe80038381f",
      "name": "Merge Title Info"
    },
    {
      "parameters": {
        "jsCode": "return [\n  {\n    json: {\n      forbiddenGenres: [\"sc_fantasy\", \"sc_syfy\"]\n    }\n  }\n];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -416,
        544
      ],
      "id": "d3d4c9ed-941b-4f9b-ba39-578883a754e0",
      "name": "Forbidden Genres"
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
        -192,
        400
      ],
      "id": "0b1d9141-472b-4dc9-b4b6-1f8a1b73927f",
      "name": "Merge Genre Info"
    },
    {
      "parameters": {
        "rules": {
          "values": [
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "leftValue": "={{ Array.isArray($json.genres) && Array.isArray($json.forbiddenGenres) \n    ? ($json.genres.some(g => $json.forbiddenGenres.includes(g)) ? 1 : 0)\n    : 0 }}\n",
                    "rightValue": 1,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    },
                    "id": "7b5be8d3-a7f3-4d30-a561-b8b8b687b92a"
                  }
                ],
                "combinator": "and"
              }
            },
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "id": "5058a156-685f-4de9-83d7-d3192a9aafd2",
                    "leftValue": "={{ Array.isArray($json.genres) && Array.isArray($json.forbiddenGenres) \n    ? ($json.genres.some(g => $json.forbiddenGenres.includes(g)) ? 1 : 0)\n    : 0 }}\n",
                    "rightValue": 0,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    }
                  }
                ],
                "combinator": "and"
              }
            }
          ]
        },
        "looseTypeValidation": true,
        "options": {}
      },
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3.2,
      "position": [
        32,
        400
      ],
      "id": "211fbb2b-4d53-4338-bab7-b0798e8f266e",
      "name": "Filter By Genre"
    },
    {
      "parameters": {
        "chatId": "1629769618",
        "text": "={{ $('Parse FB2').item.json.title }} \nIs filtered by the genre\n{{ $json.forbiddenGenres }}",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        256,
        256
      ],
      "id": "63dd3252-c687-4919-b5fb-250b0d2843ad",
      "name": "Filtered by Genre",
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
        "jsCode": "return [\n  {\n    json: {\n      forbiddenAuthors: [\"Иван Петров\", \"Wolf\"]\n    }\n  }\n];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        240,
        608
      ],
      "id": "c4554540-7917-4cce-aa4e-d9a6ff4599d7",
      "name": "Forbidden Autors"
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
        480,
        480
      ],
      "id": "fdcc9d1d-d719-4f6b-9253-a58a54cd48b8",
      "name": "Merge Authors Info"
    },
    {
      "parameters": {
        "rules": {
          "values": [
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "leftValue": "={{ Array.isArray($json.authors) && Array.isArray($json.forbiddenAythors) \n    ? ($json.authors.some(g => $json.forbiddenAythors.includes(g)) ? 1 : 0)\n    : 0 }}\n",
                    "rightValue": 1,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    },
                    "id": "7b5be8d3-a7f3-4d30-a561-b8b8b687b92a"
                  }
                ],
                "combinator": "and"
              }
            },
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "id": "5058a156-685f-4de9-83d7-d3192a9aafd2",
                    "leftValue": "={{ Array.isArray($json.authors) && Array.isArray($json.forbiddenAythors) \n    ? ($json.authors.some(g => $json.forbiddenAythors.includes(g)) ? 1 : 0)\n    : 0 }}\n",
                    "rightValue": 0,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    }
                  }
                ],
                "combinator": "and"
              }
            }
          ]
        },
        "looseTypeValidation": true,
        "options": {}
      },
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3.2,
      "position": [
        704,
        480
      ],
      "id": "c6d70884-2c61-4d08-a5c4-33e71a27bcea",
      "name": "Filter By Author"
    },
    {
      "parameters": {
        "chatId": "1629769618",
        "text": "={{ $('Parse FB2').item.json.title }} \nIs filtered by the author\n{{ $json.forbiddenAuthors }}",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        928,
        256
      ],
      "id": "7a2d0a92-9103-41b9-a4a7-76170abd3cc9",
      "name": "Filtered by Author",
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
        "jsCode": "return [\n  {\n    json: {\n      forbiddenLang: [\"uk\", \"it\"]\n    }\n  }\n];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        928,
        608
      ],
      "id": "e1fba11a-ee8e-4594-a4ae-c1f8d9324a4a",
      "name": "Forbidden Language"
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
        1152,
        480
      ],
      "id": "b3099b35-2a27-4e5b-9702-897cbfa77af6",
      "name": "Merge Lang Info"
    },
    {
      "parameters": {
        "rules": {
          "values": [
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "leftValue": "={{ $json.lang && Array.isArray($json.forbiddenLang) \n    ? ($json.forbiddenLang.includes($json.lang) ? 1 : 0)\n    : 0 }}",
                    "rightValue": 1,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    },
                    "id": "7b5be8d3-a7f3-4d30-a561-b8b8b687b92a"
                  }
                ],
                "combinator": "and"
              }
            },
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "loose",
                  "version": 2
                },
                "conditions": [
                  {
                    "id": "5058a156-685f-4de9-83d7-d3192a9aafd2",
                    "leftValue": "={{ $json.lang && Array.isArray($json.forbiddenLang) \n    ? ($json.forbiddenLang.includes($json.lang) ? 1 : 0)\n    : 0 }}",
                    "rightValue": 0,
                    "operator": {
                      "type": "number",
                      "operation": "equals"
                    }
                  }
                ],
                "combinator": "and"
              }
            }
          ]
        },
        "looseTypeValidation": true,
        "options": {}
      },
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3.2,
      "position": [
        1376,
        480
      ],
      "id": "c9e328bf-2a4c-4c4a-b770-3807458640ab",
      "name": "Filter By Language"
    },
    {
      "parameters": {
        "chatId": "1629769618",
        "text": "={{ $('Parse FB2').item.json.title }} \nIs filtered by the language\n{{ $json.forbiddenLang }}",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [
        1600,
        256
      ],
      "id": "9697893d-c883-46ba-b285-9b5d1a97c945",
      "name": "Filtered by Lang",
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
        "jsCode": "// Map of keyword to tag\nconst keywordTagMap = {\n  \"Падальщик\": \"Попаданцы\",\n  \"Попада\": \"Попаданцы\",\n  \"ЕщеСлово\": \"ОсобыйТег\"\n};\n\nconst resultTags = [];\n\nconst { title = \"\", annotation = \"\" } = $input.first().json;\n\n// Convert title and annotation to lowercase once\nconst titleLower = title.toLowerCase();\nconst annotationLower = annotation.toLowerCase();\n\n// Loop through keywords and check title + annotation (case-insensitive)\nObject.entries(keywordTagMap).forEach(([word, tag]) => {\n  const wordLower = word.toLowerCase();\n  if (titleLower.includes(wordLower) || annotationLower.includes(wordLower)) {\n    resultTags.push(tag);\n  }\n});\n\n// Remove duplicates if the same tag is added multiple times\nconst uniqueTags = [...new Set(resultTags)];\n\nreturn [\n  {\n    json: {\n      tags: resultTags\n    }\n  }\n];\n"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        1584,
        672
      ],
      "id": "274fe771-9ed9-4cfd-93ee-b555ea524b1b",
      "name": "Add Tags"
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
        1824,
        544
      ],
      "id": "8dd48e31-e700-47bd-b630-008c6213eef0",
      "name": "Merge Tag Info"
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
    "Parse FB2": {
      "main": [
        [
          {
            "node": "Forbidden Titles",
            "type": "main",
            "index": 0
          },
          {
            "node": "Merge Title Info",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Merge": {
      "main": [
        []
      ]
    },
    "Filter By Title": {
      "main": [
        [
          {
            "node": "Filtered by Title",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Forbidden Genres",
            "type": "main",
            "index": 0
          },
          {
            "node": "Merge Genre Info",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Forbidden Titles": {
      "main": [
        [
          {
            "node": "Merge Title Info",
            "type": "main",
            "index": 1
          }
        ]
      ]
    },
    "Merge Title Info": {
      "main": [
        [
          {
            "node": "Filter By Title",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Forbidden Genres": {
      "main": [
        [
          {
            "node": "Merge Genre Info",
            "type": "main",
            "index": 1
          }
        ]
      ]
    },
    "Merge Genre Info": {
      "main": [
        [
          {
            "node": "Filter By Genre",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Filter By Genre": {
      "main": [
        [
          {
            "node": "Filtered by Genre",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Forbidden Autors",
            "type": "main",
            "index": 0
          },
          {
            "node": "Merge Authors Info",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Forbidden Autors": {
      "main": [
        [
          {
            "node": "Merge Authors Info",
            "type": "main",
            "index": 1
          }
        ]
      ]
    },
    "Merge Authors Info": {
      "main": [
        [
          {
            "node": "Filter By Author",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Filter By Author": {
      "main": [
        [
          {
            "node": "Filtered by Author",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Forbidden Language",
            "type": "main",
            "index": 0
          },
          {
            "node": "Merge Lang Info",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Forbidden Language": {
      "main": [
        [
          {
            "node": "Merge Lang Info",
            "type": "main",
            "index": 1
          }
        ]
      ]
    },
    "Merge Lang Info": {
      "main": [
        [
          {
            "node": "Filter By Language",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Filter By Language": {
      "main": [
        [
          {
            "node": "Filtered by Lang",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Add Tags",
            "type": "main",
            "index": 0
          },
          {
            "node": "Merge Tag Info",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Add Tags": {
      "main": [
        [
          {
            "node": "Merge Tag Info",
            "type": "main",
            "index": 1
          }
        ]
      ]
    },
    "Merge Tag Info": {
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
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "versionId": "b7be1f32-2420-4f58-ae4e-6e4993416a27",
  "meta": {
    "templateCredsSetupCompleted": true,
    "instanceId": "dae826cbf806e76f879796dd5b506b99ee08f90440c85f2b42e963933ca20a50"
  },
  "id": "ZRghaTFrj7wrQutY",
  "tags": []
}
