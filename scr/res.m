%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright (c) 2016, University of British Columbia (UBC)  All rights reserved. %%
%%                                                                                %%
%% Redistribution  and  use  in  source   and  binary  forms,   with  or  without %%
%% modification,  are permitted  provided that  the following conditions are met: %%
%%   * Redistributions   of  source   code  must  retain   the   above  copyright %%
%%     notice,  this   list   of   conditions   and   the  following  disclaimer. %%
%%   * Redistributions  in  binary  form  must  reproduce  the  above   copyright %%
%%     notice, this  list  of  conditions  and the  following  disclaimer in  the %%
%%     documentation and/or  other  materials  provided  with  the  distribution. %%
%%   * Neither the name of the University of British Columbia (UBC) nor the names %%
%%     of   its   contributors  may  be  used  to  endorse  or   promote products %%
%%     derived from  this  software without  specific  prior  written permission. %%
%%                                                                                %%
%% THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" %%
%% AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE %%
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE %%
%% DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE %%
%% FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL %%
%% DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR %%
%% SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER %%
%% CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, %%
%% OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE %%
%% OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                        Results plotting using Matlab                           %%
%%             Author: Ameer Abdelhadi (ameer.abdelhadi@gmail.com)                %%
%% Cell-based interleaved FIFO :: The University of British Columbia :: Nov. 2016 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

T = readtable('../res.csv')

a=axes('units','normalized','position',[.1 .25 .8 .7],'xlim',[0 length(T.Sender)],'xtick',1:length(T.Sender),'xticklabel',T.Sender)
xlabel(a,'Sender')
b=axes('units','normalized','position',[.1 .1 .8 0.000001],'xlim',[0 length(T.Receiver)],'xtick',1:length(T.Receiver),'xticklabel',T.Receiver)
xlabel(b,'Receiver')
