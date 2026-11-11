/*
module gameController(
input ? [4:0]button,
input ? 
);

int state = 0;

void updater()
{
	if(state == IDLE)
	{
		mainMenuLooper();
	}
	else if(state == ENTER_GAME)
	{
		int gameChoose = 0;
		
		state = LOAD;
	}
	else if(state == LOAD)
	{
		// find songData
		// set output to tonePlayer
		// other...
	}
	else if(state == PLAYING)
	{
		//update tones position in LED Martix
		
		//check the button to correct tone
		
		//if correct, add score
		
		//set progress LED;
		if(songData.idx>=25%)
			Progress.LED |= 4'b1000;
		if(songData.idx>=50%)
			Progress.LED |= 4'b0100;
		if(songData.idx>=75%)
			Progress.LED |= 4'b0010;
		if(songData.idx>=100%)
			Progress.LED |= 4'b0001;
			
		//end
		if(songData.finish) state = FINISHED;
	}
	else if(state == FINISHED)
	{
		// shine Play Score in digital LED
		// play some effect on LED Martix
		
		if(cnt == finish_animation_end) state = IDLE;
	}
} 



endmodule
*/