#
# TODO: some doc here
#
#
# 3rd party modules
should = require('chai').should()
_ = require '../mixins.coffee'
#
# Loading corpus
_.e.corpus.load './corpus.json'
#
# Preparing words for tests.
#
TEST_NAME = 'spell mixin'
words = {}
words.easy = {}
words.easy.correct = []
words.easy.miss = []
#
words.medium = {}
words.medium.correct = []
words.medium.miss = []
#
words.hard = {}
words.hard.correct = []
words.hard.miss = []
#
words.bad = []
words.eg = {}
words.eg.miss = [
  'sheeeeeep', 'peepple', 'sheeple', 'inSIDE', 'jjoobbb',
  'weke', 'CUNsperrICY'
]
words.eg.ans = [
  'sheep', 'people', 'NO SUGGESTION', 'inside', 'job',
  'wake', 'conspiracy'
]
#
_.e.print "Generating random misspelled word for #{TEST_NAME} tests."
_.times 5, ->
  _.e.put '.'
  word = _.e.randWord(5, 4).word
  words.easy.correct.push word
  words.easy.miss.push _.e.misspell word, 'easy'
  #
  _.e.put '.'
  word = _.e.randWord(7, 5).word
  words.medium.correct.push word
  words.medium.miss.push _.e.misspell word, 'medium'
  #
  _.e.put '.'
  word = _.e.randWord(10, 7).word
  words.hard.correct.push word
  words.hard.miss.push _.e.misspell word, 'hard'
  #
  _.e.put '.'
  alpha = 'bcdfghjlkmnpqrstvxyz'.split ''
  words.bad.push _(alpha).chain().shuffle().first(10).value().join('')
  return
#
_.e.print ''
#
#
tmp00 = '-----------'
describe "#{tmp00}\n  #{TEST_NAME}\n  #{tmp00}", ->
  #
  # looping over the two kinds of algorithm
  #
  _.each ['SLOWER', 'SIMPLER'], (algo) ->
    msg = "\n- Testing #{algo} algorithm"
    if algo is 'SIMPLER'
      force = no
    else
      force = yes
    #
    describe msg, ->
      #
      #
      describe '- Testing challenge words', ->
        _.each words.eg.miss, (word, index) ->
          ans = words.eg.ans[index]
          it "-  '#{word}' should be corrected into '#{ans}'", ->
            _.e.spell(word, force).should.equal ans
      #
      #
      describe '- Testing NO SUGGESTIONS', ->
        _.each words.bad, (word) ->
          it "- should be no suggestion for '#{word}'", ->
             _.e.spell(word).should.equal 'NO SUGGESTION'
      #
      # Generating the 3 diffilcuty testing levels
      #
      _.each ['easy', 'medium', 'hard'], (level) ->
        #
        # Words too long makes the testing too slow. If it works for 7
        # letters long word, why wouldn't it work for 15 letters long ???
        #
        describe "- Level: #{level} word", ->
          describe '- not scrambled', ->
            _.each words[level].correct, (word) ->
              it "- '#{word}' should be correctly spelled", ->
                _.e.spell(word, force).should.equal 'Spelling is correct'
            return
          #
          #
          describe "- scrambled", ->
            _.each words[level].miss, (word, index) ->
              wordCorrect = words[level].correct[index]
              #
              shouldBe = "-  '#{word}' should be corrected into"
              shouldBe = "#{shouldBe} '#{wordCorrect}'"
              it shouldBe, ->
                _.e.spell(word, force).should.equal wordCorrect
            return
  return
#
