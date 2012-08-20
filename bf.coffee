# Copyright 2012 Manuel Cerón <ceronman@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

codeToChar = (code) -> String.fromCharCode(code)[0]
charToCode = (char) -> char.charCodeAt()

class VM

  constructor: ->
    @pointer = 0
    @position = 0
    @buffer = {}
    @input = []
    @output = []
    @program = []
    @stack = []
    @loops = {}

  load: (program, input) ->

    cleanProgram = []
    for instruction in program
      if instruction in ['>', '<', '+', '-', ',', '.', '[', ']']
        cleanProgram.push(instruction)
    stack = []
    for position, instruction of cleanProgram
      if instruction == '['
        stack.push(position)
      if instruction == ']'
        initpos = stack.pop()
        if not initpos?
          throw 'Syntax error:' + position
        @loops[initpos] = position
      @program.push instruction

    if @program.length == 0
      throw "Empty program"

    if stack.length != 0
      throw 'Syntax error:' + position

    for char in input
      @input.push charToCode(char)

    @checkbuffer()

  runStep: ->
    instruction = @program[@position]
    if not instruction
      return true
    else
      @[instruction]()
      @position++
      return false

  outputString: -> (codeToChar(code) for code in @output when code != 0).join('')
  inputString: ->  (codeToChar(code) for code in @input  when code != 0).join('')

  checkbuffer: ->
    @buffer[@pointer] = @buffer[@pointer] ? 0

  '>': ->
    @pointer += 1
    @checkbuffer()

  '<': ->
    @pointer -= 1
    @checkbuffer()

  '+': ->
    @buffer[@pointer] += 1
    @buffer[@pointer] = 0 if @buffer[@pointer] > 255

  '-': ->
    @buffer[@pointer] -= 1
    @buffer[@pointer] = 255 if @buffer[@pointer] < 0

  ',': ->
    if @input.length == 0
      @buffer[@pointer] = 0
      return

    value = @input.splice(0, 1)[0]
    @buffer[@pointer] = value

  '.': ->
    @output.push(@buffer[@pointer])

  '[': ->
    if (@buffer[@pointer] != 0)
      @stack.push(@position - 1)
    else
      @position = @loops[@position]

  ']': ->
    @position = @stack.pop()

window.BF =
  steps: 0
  done: true
  vm: null
  stepSize: 10000

  load: (program, input)->
    @steps = 0
    @vm = new VM()
    @vm.load(program, input)
    @done = false

  run: ->
    for i in [0..@stepSize]
      if @done
        break
      @step()

    if not @done
      setTimeout (=> @run()), 0

  step: ->
    @done = @vm.runStep()
    @steps++

  watch: ->
    if not @vm
      return

    output = @vm.outputString()
    if output == ""
      $('#output').text('')
      $('#output').append(' ')
    else
      $('#output').text(output)

    input = @vm.inputString()
    if input == ""
      $('#inputTape').text('')
      $('#inputTape').append(' ')
    else
      $('#inputTape').text(input)

    if @done
      $('#progress').text("Ran in #{@steps} steps")
      $('#run').text('Run')
      $('#step').text('Step by Step')
      $('#step, #program, #input').removeAttr('disabled')
    else
      $('#progress').text("Running step #{@steps}")
      setTimeout (=> @watch()), 200
    if @previousSPAN
      @previousSPAN.removeClass('current')

    currentSPAN = $("#execution span:nth-child(#{@vm.position + 1})")
    currentSPAN.addClass('current')
    @previousSPAN = currentSPAN

    buffer = $('#buffer')
    buffer.empty()
    keys = Object.keys(@vm.buffer).sort((a, b) -> parseInt(a) - parseInt(b))
    for key in keys
      child = $("<span> #{@vm.buffer[key]} <span/>")
      buffer.append child
      if parseInt(key) == @vm.pointer
        child.addClass('current')

  loadExecutionUI: ->
    execDIV = $('#execution')
    execDIV.empty()
    for instruction in @vm.program
      child = $("<span>#{instruction}</span>")
      @previousSPAN = null
      execDIV.append(child);
      execDIV.append(" ");

  prepareUI: ->
    $('#output').text('')
    $('#output').append(' ')
    $('#inputTape').text('')
    $('#inputTape').append(' ')
    $('#error').text('')
    $('#run').text('Run')
    $('#step').text('Step by step')
    $('#step, #program, #input').removeAttr('disabled')

  runningUI: ->
    @loadExecutionUI()
    $('#step, #program, #input').attr('disabled', 'disabled')
    $('#run').text('Matar')

  steppingUI: ->
    @loadExecutionUI()
    $('#program, #input').attr('disabled', 'disabled')
    $('#step').text('Next')
    $('#run').text('Finish')

BF.loadAndRun = ->
  if BF.done
    try
      program = $("#program").val()
      input = $("#input").val()
      BF.load(program, input)
      BF.prepareUI()
      BF.runningUI()
      BF.run()
      BF.watch()
    catch error
      BF.done = true
      $('#error').text(error)
  else
    if $('#run').text() == 'Finish'
      BF.runningUI()
      BF.run()
    else
      BF.done = true

BF.loadAndStep = ->
  if BF.done
    try
      program = $("#program").val()
      input = $("#input").val()
      BF.load(program, input)
      BF.prepareUI()
      BF.steppingUI()
      BF.watch()
    catch error
      BF.done = true
      $('#error').text(error)
  else
    BF.step()

BF.clean = ->
  BF.done = true
  BF.vm = null
  BF.prepareUI()
  $('#buffer').text('')
  $('#buffer').append(' ')
  $('#execution').text('')
  $('#execution').append(' ')
  $('#program, #input').val('')


@runTuring = (program, input)->
  vm = new VM()
  vm.load(program, input)
  done = false
  initTime = new Date().getTime()
  while not done
    done = vm.runStep()
    stepTime = new Date().getTime()
    if stepTime - initTime > 2000
      break
  return vm.outputString()
