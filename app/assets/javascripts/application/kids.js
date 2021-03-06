mumuki.load(function () {

  mumuki.resize(function () {
    var margin = 15;
    var fullMargin = margin * 2;

    var gbsBoard = $('.mu-kids-state');

    var dimension = gbsBoard.height() * 1.25 - fullMargin;
    gbsBoard.width(dimension);

    var $muKidsExercise = $('.mu-kids-exercise');
    var $muKidsExerciseDescription = $('.mu-kids-exercise-description');

    $muKidsExerciseDescription.width($muKidsExercise.width() - gbsBoard.width() - margin);

    gbsBoard.each(function (i) {
      gsBoardScale($(gbsBoard[i]));
    });

    var $muKidsBlocks = $('.mu-kids-blocks');
    var $blockArea = $muKidsBlocks.find('#blocklyDiv');
    var $blockSvg = $muKidsBlocks.find('.blocklySvg');

    $blockArea.width($muKidsBlocks.width());
    $blockArea.height($muKidsBlocks.height());

    $blockSvg.width($muKidsBlocks.width());
    $blockSvg.height($muKidsBlocks.height());

    function gsBoardScale($element) {
      var $table = $element.find('gs-board > table');
      $table.css('transform', 'scale(1)');
      var scaleX = ($element.width() - fullMargin * 2) / $table.width();
      var scaleY = ($element.height() - fullMargin * 2) / $table.height();
      $table.css('transform', 'scale(' + Math.min(scaleX, scaleY) + ')');
    }

  });

  var $speechParagraphs;
  var currentParagraphIndex = 0;
  var $prevSpeech = $('.mu-kids-character-speech-bubble-normal > .mu-kids-prev-speech').hide();
  var $nextSpeech = $('.mu-kids-character-speech-bubble-normal > .mu-kids-next-speech');
  var $speechTabs = $('.mu-kids-character-speech-bubble-tabs > li:not(.separator)');
  var $bubble = $('.mu-kids-character-speech-bubble').children('.mu-kids-character-speech-bubble-normal');
  var $texts = $bubble.children('.description, .hint');

  updateSpeechParagraphs();
  function updateSpeechParagraphs() {
    $speechParagraphs = $('.mu-kids-character-speech-bubble > .mu-kids-character-speech-bubble-normal > div.' + getSelectedTabName() + ' > p');
    showParagraph(0);
  }

  $speechTabs.each(function (i) {
    var $tab = $($speechTabs[i]);
    $tab.click(function () {
      $speechTabs.removeClass('active');
      $tab.addClass('active');
      $texts.hide();
      $bubble.children('.' + $tab.data('target')).show();
      $bubble.scroll(0);
      hideCurrentParagraph();
      updateSpeechParagraphs();
    })
  });

  $nextSpeech.click(function () {
    hideCurrentParagraph();
    showNextParagraph();
  });
  $prevSpeech.click(function () {
    hideCurrentParagraph();
    showPrevParagraph();
  });

  function getSelectedTabName() {
    return $speechTabs.filter(".active").data('target');
  }

  function hideCurrentParagraph() {
    $($speechParagraphs[currentParagraphIndex]).hide();
  }

  function showPrevParagraph() {
    showParagraph(currentParagraphIndex - 1);
  }

  function showNextParagraph() {
    showParagraph(currentParagraphIndex + 1);
  }

  function showParagraph(index) {
    $($speechParagraphs[index]).show();
    setVisibility($prevSpeech, index !== 0);
    setVisibility($nextSpeech, index !== $speechParagraphs.length - 1);

    currentParagraphIndex = index;
  }

  function setVisibility(element, isVisible) {
    if (isVisible) element.show(); else element.hide();
  }

  function autoScrollBubble(toBottom) {
    var SCROLL_TIME = 1000;
    var PAUSE_TIME = 2000;

    setTimeout(function() {
      $bubble.animate({ scrollTop: toBottom ? $bubble.height() : 0 }, {
        duration: SCROLL_TIME,
        complete: function() {
          autoScrollBubble(!toBottom);
        }
      });
    }, PAUSE_TIME);
  }
  autoScrollBubble();

  mumuki.kids = {

    getResultsModal: function () {
      return $('#kids-results');
    },

    getResultsAbortedModal: function () {
      return $('#kids-results-aborted');
    },

    getCharaterImage: function () {
      return $('.mu-kids-character > img');
    },

    getCharacterBubble: function () {
      return $('.mu-kids-character-speech-bubble');
    },

    getSubmissionResult: function () {
      return $('.submission-results');
    },

    getOverlay: function () {
      return $('.mu-kids-overlay');
    },

    showResult: function (data) {  // This function is called by the custom runner
      mumuki.updateProgressBarAndShowModal(data);
      if (data.guide_finished_by_solution) return;
      mumuki.kids.resultAction[data.status](data);
    },

    restart: function () {  // This function is called by the custom runner
      mumuki.kids._hideMessageOnCharacterBubble();
      var $bubble = mumuki.kids.getCharacterBubble();
      Object.keys(mumuki.kids.resultAction).forEach($bubble.removeClass.bind($bubble));
      mumuki.kids.getCharaterImage().attr('src', '/anim_amarillo.svg');
    },

    _hideMessageOnCharacterBubble: function () {
      var $bubble = mumuki.kids.getCharacterBubble();
      $bubble.find('.mu-kids-character-speech-bubble-tabs').show();
      $bubble.find('.mu-kids-character-speech-bubble-normal').show();
      $bubble.find('.mu-kids-character-speech-bubble-failed').hide();
      Object.keys(mumuki.kids.resultAction).forEach($bubble.removeClass.bind($bubble));
      mumuki.kids.getOverlay().hide();
    },

    _showMessageOnCharacterBubble: function (data) {
      var $bubble = mumuki.kids.getCharacterBubble();
      $bubble.find('.mu-kids-character-speech-bubble-tabs').hide();
      $bubble.find('.mu-kids-character-speech-bubble-normal').hide();
      $bubble.find('.mu-kids-character-speech-bubble-failed').show().html(data.title_html);
      $bubble.addClass(data.status);
      mumuki.kids.getOverlay().show();
    },

    _showOnSuccessPopup: function (data) {
      mumuki.kids.getSubmissionResult().html(data.html);
      mumuki.kids.getCharaterImage().attr('src', '/amarillo_exito.svg');
      mumuki.kids._showMessageOnCharacterBubble(data);
      setTimeout(function () {
        var results_kids_modal = mumuki.kids.getResultsModal();
        if (results_kids_modal) {
          results_kids_modal.modal({
            backdrop: 'static',
            keyboard: false
          });
          results_kids_modal.find('.modal-header').first().html(data.title_html);
          results_kids_modal.find('.modal-footer').first().html(data.button_html);
          mumuki.kids._showCorollaryCharacter();
        }
      }, 1000 * 4);
    },

    _showOnFailurePopup: function () {
      mumuki.kids.submitButton.disable();
      mumuki.kids.getResultsAbortedModal().modal();
      mumuki.submission.animateTimeoutError(mumuki.kids.submitButton);
    },

    _showOnCharacterBubble: function (data) {
      mumuki.kids.getCharaterImage().attr('src', '/amarillo_fracaso.svg');
      mumuki.kids._showMessageOnCharacterBubble(data);
    },

    _showCorollaryCharacter: function () {
      var image = $('#mu-kids-corollary-animation')[0];
      image && setTimeout(function () {
        image.src = mumuki.characters.magnifying_glass_apparition.url;
        setTimeout(function () {
          image.src = mumuki.characters.magnifying_glass_loop.url;
        }, mumuki.characters.magnifying_glass_apparition.duration);
      }, 500);
    },

    resultAction: {}

  };

  _createSubmitButton = function () {
    var submitButton = $('#kids-btn-retry');
    var submissionControl = $('.submission_control');
    return new mumuki.submission.SubmitButton(submitButton, submissionControl);
  };

  mumuki.kids.submitButton = _createSubmitButton();

  mumuki.showKidsResult = function (data) {
    mumuki.updateProgressBarAndShowModal(data);
    if (data.guide_finished_by_solution) return;
    mumuki.kids.getSubmissionResult().html(data.html);

    var results_kids_modal = mumuki.kids.getResultsModal();
    if (results_kids_modal) {
      results_kids_modal.modal();
      results_kids_modal.find('.modal-header').first().html(data.title_html);
      results_kids_modal.find('.modal-footer').first().html(data.button_html);
    }
  };

  mumuki.kids.resultAction.passed = mumuki.kids._showOnSuccessPopup;
  mumuki.kids.resultAction.passed_with_warnings = mumuki.kids._showOnSuccessPopup;

  mumuki.kids.resultAction.aborted = mumuki.kids._showOnFailurePopup;

  mumuki.kids.resultAction.failed = mumuki.kids._showOnCharacterBubble;
  mumuki.kids.resultAction.errored = mumuki.kids._showOnCharacterBubble;
  mumuki.kids.resultAction.pending = mumuki.kids._showOnCharacterBubble;

});
