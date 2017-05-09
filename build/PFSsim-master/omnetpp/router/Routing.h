//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
//

#ifndef __ROUTING_H__
#define __ROUTING_H__

#include <omnetpp.h>
#include "General.h"

class Routing : public cSimpleModule
{
private:
    int StoPRoutingTable[MAX_DS];
    void readProxyRoutingFile(const char * path);
protected:
    int numDS;
	int numProxies;
	void initialize();
	virtual void handleMessage(cMessage *msg);
	void handleSPacketPropagation(sPacket * spkt);
};

#endif
