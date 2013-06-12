#!/usr/bin/env coffee

natural = require 'natural'
sylvester = require 'sylvester'
fs = require 'fs'

if process.argv[2]? and process.argv[3]?
  # Read in the given file
  fs.readFile process.argv[2], (err, data) ->
    # Tokenize into sentences
    tokenizer = new natural.RegexpTokenizer({pattern: /[\.!\?\r\n#]+/})
    file = strip_markdown data.toString()
    sentences = tokenizer.tokenize file
    sentences = (sentence.trim() for sentence in sentences)
    
    console.log sentences.length
    
    # Take the sentences and generate the tf-idf vectors
    transition = [];
    TfIdf = natural.TfIdf
    tfidf = new TfIdf()
    
    tfidf.addDocument(sentence) for sentence in sentences
    for sentence in sentences
      row = [];
      tfidf.tfidfs sentence, (i, measure) ->
        if sentence is sentences[i]
          row.push(1)
        else
          row.push(measure + 1)
      transition.push(transition_modified(row))
    
    # Find the page rank off the given
    # Transition matrix...
    trans_mat = $M(transition)
    rank_vec = make_vec(sentences.length)
    for i in [1..200]
      rank_vec = rank_vec.x(trans_mat)
    
    # Create an array of objects with sentences and scores
    scored = []
    for i in [1..sentences.length]
      scored.push({score: rank_vec.e(1, i), sentence: sentences[i-1], idx: i})
    
    scored.sort compare_scores
    scored = scored.splice(0, process.argv[3])
    scored.sort compare_idx
    
    summary = []
    summary.push(good.sentence) for good in scored
    
    console.log(summary.join(".  ") + ".")

else
  console.log "Usage:"
  console.log "\tsummary [file] [limit]"

compare_idx = (a, b) ->
  a.idx - b.idx

compare_scores = (a, b) ->
  b.score - a.score

make_vec = (len) ->
  new_vec = [];
  new_vec.push 1
  new_vec.push(0) for i in [1...len]
  $M([new_vec])

transition_modified = (r) ->
  divider = 0
  divider += score for score in r
  r = (score/divider for score in r)

strip_markdown = (str) ->
  # Extra quotes
  str = str.replace /"/g, ''
  
  # Links and Images
  str = str.replace /!\[(.*?)?\]\((.*?)?\)/g, '$1'
  str = str.replace /!?\[(.*?)?\]\((.*?)?\)/g, '$1'
  
  # Footnotes
  str = str.replace /\[\^(.*?)\]:?/g, ''
  
  # Bold and italics
  str = str.replace /\*{1,3}([^\*]*?)\*{1,3}/g, '$1'
  str = str.replace /_{1,3}([^\*]*?)_{1,3}/g, '$1'
  
  # List and blockquotes
  str = str.replace /^\s*[\*\s]+(.*?)/g, '$1'
  str = str.replace /^\s*[\>\s]*(.*?)/g, '$1'
  str = str.replace /^\s*[\*\s]+(.*?)/g, '$1'
  str = str.replace /^\s*[\>\s]*(.*?)/g, '$1'
  
  # Headings
  str = str.replace /#/g, ''
  
  # comments
  str = str.replace /<!--(.*?)-->/g, ''
  
  # Extra whitespace
  str = str.replace /\s+/g, ' '
  
  # Code
  str = str.replace /```(.*?)```/g, ''